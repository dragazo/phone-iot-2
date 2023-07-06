use std::sync::atomic::{AtomicBool, Ordering as MemOrder};
use std::collections::VecDeque;
use std::time::{Duration, Instant};
use std::sync::Mutex;
use std::rc::Rc;
use std::thread;

use netsblox_vm::project::{Project, IdleAction, ProjectStep, Input};
use netsblox_vm::std_system::StdSystem;
use netsblox_vm::bytecode::{ByteCode, Locations};
use netsblox_vm::runtime::{CustomTypes, GetType, EntityKind, IntermediateType, ErrorCause, Value, FromAstError, Config, Command, CommandStatus, Key};
use netsblox_vm::gc::{Gc, RefLock, Collect, Arena, Rootable, Mutation};
use netsblox_vm::json::Json;
use netsblox_vm::ast;

const SERVER_URL: &'static str = "https://editor.netsblox.org";
const IDLE_SLEEP_THRESH: usize = 256;
const IDLE_SLEEP_TIME: Duration = Duration::from_millis(1);
const MESSAGE_DURATION: Duration = Duration::from_secs(10);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum NativeType {}

#[derive(Debug)]
enum NativeValue {}
impl GetType for NativeValue {
    type Output = NativeType;
    fn get_type(&self) -> Self::Output {
        unreachable!()
    }
}

struct EntityState;
impl From<EntityKind<'_, '_, C, StdSystem<C>>> for EntityState {
    fn from(_: EntityKind<'_, '_, C, StdSystem<C>>) -> Self {
        EntityState
    }
}

enum Intermediate {
    Json(Json),
    Image(Vec<u8>),
    Audio(Vec<u8>),
}
impl IntermediateType for Intermediate {
    fn from_json(json: Json) -> Self {
        Self::Json(json)
    }
    fn from_image(img: Vec<u8>) -> Self {
        Self::Image(img)
    }
    fn from_audio(audio: Vec<u8>) -> Self {
        Self::Audio(audio)
    }
}

struct C;
impl CustomTypes<StdSystem<C>> for C {
    type NativeValue = NativeValue;
    type Intermediate = Intermediate;

    type EntityState = EntityState;

    fn from_intermediate<'gc>(mc: &Mutation<'gc>, value: Self::Intermediate) -> Result<Value<'gc, C, StdSystem<C>>, ErrorCause<C, StdSystem<C>>> {
        Ok(match value {
            Intermediate::Json(x) => Value::from_json(mc, x)?,
            Intermediate::Image(x) => Value::Image(Rc::new(x)),
            Intermediate::Audio(x) => Value::Audio(Rc::new(x)),
        })
    }
}

#[derive(Collect)]
#[collect(no_drop, bound = "")]
struct Env<'gc, C: CustomTypes<StdSystem<C>>> {
                               proj: Gc<'gc, RefLock<Project<'gc, C, StdSystem<C>>>>,
    #[collect(require_static)] locs: Locations,
}
type EnvArena<S> = Arena<Rootable![Env<'_, S>]>;

fn get_env<C: CustomTypes<StdSystem<C>>>(role: &ast::Role, system: Rc<StdSystem<C>>) -> Result<EnvArena<C>, FromAstError> {
    let (bytecode, init_info, locs, _) = ByteCode::compile(role).unwrap();
    Ok(EnvArena::new(Default::default(), |mc| {
        let proj = Project::from_init(mc, &init_info, Rc::new(bytecode), Default::default(), system);
        Env { proj: Gc::new(mc, RefLock::new(proj)), locs }
    }))
}

enum ProjCommand {
    SetProject { xml: String },
    Start,
}

static COMMANDS: Mutex<VecDeque<ProjCommand>> = Mutex::new(VecDeque::new());
static MESSAGES: Mutex<VecDeque<(Instant, MessageType, String)>> = Mutex::new(VecDeque::new());
static CONTROLS: Mutex<Vec<CustomControl>> = Mutex::new(Vec::new());
static INITIALIZED: AtomicBool = AtomicBool::new(false);

fn prune_messages(messages: &mut VecDeque<(Instant, MessageType, String)>) {
    while let Some(msg) = messages.front() {
        if msg.0.elapsed() < MESSAGE_DURATION {
            break;
        }
        messages.pop_front();
    }
}
fn push_message(ty: MessageType, content: String) {
    let mut msgs = MESSAGES.lock().unwrap();
    prune_messages(&mut msgs);
    msgs.push_back((Instant::now(), ty, content));
}

// -----------------------------------------------------------------

#[derive(Clone, Copy)]
pub enum CustomButtonStyle {
    Rectangle, Ellipse, Square, Circle,
}
#[derive(Clone, Copy)]
pub enum CustomTextAlign {
    Left, Center, Right,
}

#[derive(Clone, Copy)]
pub struct CustomColor {
    pub a: u8,
    pub r: u8,
    pub g: u8,
    pub b: u8,
}
#[derive(Clone)]
pub struct CustomButton {
    pub id: String,
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub back_color: CustomColor,
    pub fore_color: CustomColor,
    pub text: String,
    pub event: Option<String>,
    pub font_size: f32,
    pub style: CustomButtonStyle,
    pub landscape: bool,
}
#[derive(Clone)]
pub struct CustomLabel {
    pub id: String,
    pub x: f32,
    pub y: f32,
    pub color: CustomColor,
    pub text: String,
    pub font_size: f32,
    pub align: CustomTextAlign,
    pub landscape: bool,
}
#[derive(Clone)]
pub enum CustomControl {
    Button(CustomButton),
    Label(CustomLabel),
}

pub fn initialize() {
    if INITIALIZED.swap(true, MemOrder::Relaxed) { return }
    thread::spawn(move || {
        let config = Config::<C, StdSystem<C>> {
            command: Some(Rc::new(move |_, _, key, command, _| {
                match command {
                    Command::Print { style: _, value } => {
                        if let Some(value) = value {
                            match value.to_string() {
                                Ok(x) => push_message(MessageType::Output, x.into_owned()),
                                Err(e) => push_message(MessageType::Error, format!("print {e:?}")),
                            }
                        }
                    }
                    _ => return CommandStatus::UseDefault { key, command },
                }
                key.complete(Ok(()));
                CommandStatus::Handled
            })),
            request: None,
        };
        let system = Rc::new(StdSystem::new(SERVER_URL.to_owned(), None, config));
        let mut env = {
            let project = ast::Parser::default().parse(netsblox_vm::template::EMPTY_PROJECT).unwrap();
            get_env(&project.roles[0], system.clone()).unwrap()
        };
        let mut idle_sleeper = IdleAction::new(IDLE_SLEEP_THRESH, Box::new(move || thread::sleep(IDLE_SLEEP_TIME)));

        loop {
            let cmd = COMMANDS.lock().unwrap().pop_front();
            match cmd {
                Some(ProjCommand::SetProject { xml }) => match ast::Parser::default().parse(&xml) {
                    Ok(project) => match project.roles.as_slice() {
                        [role] => match get_env(role, system.clone()) {
                            Ok(x) => {
                                env = x;
                                push_message(MessageType::Output, "loaded project".into());
                            }
                            Err(e) => push_message(MessageType::Error, format!("project load error: {e:?}")),
                        }
                        x => push_message(MessageType::Error, format!("project load error: expected 1 role, got {}", x.len())),
                    }
                    Err(e) => push_message(MessageType::Error, format!("project load error: {e:?}")),
                }
                Some(ProjCommand::Start) => {
                    env.mutate(|mc, env| {
                        env.proj.borrow_mut(mc).input(Input::Start);
                    });
                }
                None => (),
            }

            env.mutate(|mc, env| {
                let res = env.proj.borrow_mut(mc).step(mc);
                if let ProjectStep::Error { error, proc } = &res {
                    push_message(MessageType::Error, format!("runtime error in entity {:?}: {:?}", proc.get_call_stack().last().unwrap().entity.borrow().name, error.cause));
                }
                idle_sleeper.consume(&res);
            });
        }
    });

    CONTROLS.lock().unwrap().push(CustomControl::Button(CustomButton {
        id: "test".into(),
        x: 10.0,
        y: 10.0,
        width: 50.0,
        height: 50.0,
        back_color: CustomColor { a: 255, r: 255, g: 100, b: 100 },
        fore_color: CustomColor { a: 255, r: 100, g: 255, b: 100 },
        text: "merp derp this is going to be a big thing of text that will go off the thing and be really long and stuff haha".into(),
        event: None,
        font_size: 1.0,
        style: CustomButtonStyle::Rectangle,
        landscape: false,
    }));
    CONTROLS.lock().unwrap().push(CustomControl::Button(CustomButton {
        id: "test".into(),
        x: 10.0,
        y: 40.0,
        width: 20.0,
        height: 30.0,
        back_color: CustomColor { a: 255, r: 50, g: 100, b: 100 },
        fore_color: CustomColor { a: 255, r: 200, g: 100, b: 100 },
        text: "merp derp this is going to be a big thing of text that will go off the thing and be really long and stuff haha".into(),
        event: None,
        font_size: 1.0,
        style: CustomButtonStyle::Rectangle,
        landscape: false,
    }));
}

#[derive(Clone, Copy)]
pub enum MessageType {
    Output,
    Error,
}
pub struct Status {
    pub messages: Vec<(MessageType, String)>,
    pub controls: Vec<CustomControl>,
}

pub fn get_status() -> Status {
    let messages = {
        let mut msgs = MESSAGES.lock().unwrap();
        prune_messages(&mut msgs);
        msgs.iter().map(|x| (x.1, x.2.clone())).collect()
    };
    let controls = CONTROLS.lock().unwrap().clone();
    Status { messages, controls }
}
pub fn set_project(xml: String) {
    COMMANDS.lock().unwrap().push_back(ProjCommand::SetProject { xml });
}
pub fn start_project() {
    COMMANDS.lock().unwrap().push_back(ProjCommand::Start);
}
