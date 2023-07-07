use std::sync::atomic::{AtomicBool, AtomicU64, Ordering as MemOrder};
use std::collections::BTreeMap;
use std::time::Duration;
use std::sync::Mutex;
use std::rc::Rc;
use std::{mem, thread};

use netsblox_vm::project::{Project, IdleAction, ProjectStep, Input};
use netsblox_vm::std_system::{StdSystem, RequestKey};
use netsblox_vm::bytecode::{ByteCode, Locations};
use netsblox_vm::runtime::{CustomTypes, GetType, EntityKind, IntermediateType, ErrorCause, Value, FromAstError, Config, Command, Request, CommandStatus, RequestStatus, Key};
use netsblox_vm::gc::{Gc, RefLock, Collect, Arena, Rootable, Mutation};
use netsblox_vm::json::{Json, json};
use netsblox_vm::ast;

const SERVER_URL: &'static str = "https://editor.netsblox.org";
const IDLE_SLEEP_THRESH: usize = 256;
const IDLE_SLEEP_TIME: Duration = Duration::from_millis(1);

static INITIALIZED: AtomicBool = AtomicBool::new(false);
static DART_COMMANDS: Mutex<Vec<DartCommand>> = Mutex::new(Vec::new());
static RUST_COMMANDS: Mutex<Vec<RustCommand>> = Mutex::new(Vec::new());
static PENDING_REQUESTS: Mutex<BTreeMap<DartRequestKey, RequestKey<C>>> = Mutex::new(BTreeMap::new());
static COUNTER: AtomicU64 = AtomicU64::new(0);

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

// -----------------------------------------------------------------

pub enum ButtonStyleInfo {
    Rectangle, Ellipse, Square, Circle,
}
pub enum TextAlignInfo {
    Left, Center, Right,
}

pub struct ColorInfo {
    pub a: u8,
    pub r: u8,
    pub g: u8,
    pub b: u8,
}
pub struct ButtonInfo {
    pub id: String,
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub back_color: ColorInfo,
    pub fore_color: ColorInfo,
    pub text: String,
    pub event: Option<String>,
    pub font_size: f32,
    pub style: ButtonStyleInfo,
    pub landscape: bool,
}
pub struct LabelInfo {
    pub id: String,
    pub x: f32,
    pub y: f32,
    pub color: ColorInfo,
    pub text: String,
    pub font_size: f32,
    pub align: TextAlignInfo,
    pub landscape: bool,
}

pub enum RustCommand {
    SetProject { xml: String },
    Start,
}

#[derive(PartialOrd, Ord, PartialEq, Eq)]
pub struct DartRequestKey {
    pub value: u64,
}
impl DartRequestKey {
    fn new() -> Self {
        Self { value: COUNTER.fetch_add(1, MemOrder::Relaxed) }
    }
}

pub enum DartCommand {
    Stdout { msg: String },
    Stderr { msg: String },
    AddButton { info: ButtonInfo, key: DartRequestKey },
    AddLabel { info: LabelInfo, key: DartRequestKey },
}

pub enum SimpleValue {
    Number(f64),
    String(String),
    List(Vec<SimpleValue>),
}
impl SimpleValue {
    fn into_json(self) -> Json {
        match self {
            SimpleValue::Number(x) => json!(x),
            SimpleValue::String(x) => Json::String(x),
            SimpleValue::List(x) => Json::Array(x.into_iter().map(SimpleValue::into_json).collect()),
        }
    }
}

pub enum RequestResult {
    Ok(SimpleValue),
    Err(String),
}
impl RequestResult {
    fn into_result(self) -> Result<SimpleValue, String> {
        match self {
            Self::Ok(x) => Ok(x),
            Self::Err(x) => Err(x),
        }
    }
}

pub fn initialize() {
    if INITIALIZED.swap(true, MemOrder::Relaxed) { return }
    thread::spawn(move || {
        let config = Config::<C, StdSystem<C>> {
            command: Some(Rc::new(move |_, _, key, command, _| {
                match &command {
                    Command::Print { style: _, value } => {
                        if let Some(value) = value {
                            match value.to_string() {
                                Ok(x) => DART_COMMANDS.lock().unwrap().push(DartCommand::Stdout { msg: x.into_owned() }),
                                Err(e) => DART_COMMANDS.lock().unwrap().push(DartCommand::Stderr { msg: format!("print {e:?}") }),
                            }
                        }
                    }
                    _ => return CommandStatus::UseDefault { key, command },
                }
                key.complete(Ok(()));
                CommandStatus::Handled
            })),
            request: Some(Rc::new(move |_, _, key, request, _| {
                match &request {
                    Request::Rpc { service, rpc, args } if service == "PhoneIoT" => match rpc.as_str() {
                        _ => return RequestStatus::UseDefault { key, request }
                    }
                    _ => return RequestStatus::UseDefault { key, request },
                }
            })),
        };
        let system = Rc::new(StdSystem::new(SERVER_URL.to_owned(), None, config));
        let mut env = {
            let project = ast::Parser::default().parse(netsblox_vm::template::EMPTY_PROJECT).unwrap();
            get_env(&project.roles[0], system.clone()).unwrap()
        };
        let mut idle_sleeper = IdleAction::new(IDLE_SLEEP_THRESH, Box::new(move || thread::sleep(IDLE_SLEEP_TIME)));

        loop {
            let commands = mem::take(&mut *RUST_COMMANDS.lock().unwrap());
            for cmd in commands {
                match cmd {
                    RustCommand::SetProject { xml } => match ast::Parser::default().parse(&xml) {
                        Ok(project) => match project.roles.as_slice() {
                            [role] => match get_env(role, system.clone()) {
                                Ok(x) => {
                                    env = x;
                                    DART_COMMANDS.lock().unwrap().push(DartCommand::Stdout { msg: "loaded project".into() });
                                }
                                Err(e) => DART_COMMANDS.lock().unwrap().push(DartCommand::Stderr { msg: format!("project load error: {e:?}") }),
                            }
                            x => DART_COMMANDS.lock().unwrap().push(DartCommand::Stderr { msg: format!("project load error: expected 1 role, got {}", x.len()) } ),
                        }
                        Err(e) => DART_COMMANDS.lock().unwrap().push(DartCommand::Stderr { msg: format!("project load error: {e:?}") }),
                    }
                    RustCommand::Start => {
                        env.mutate(|mc, env| {
                            env.proj.borrow_mut(mc).input(Input::Start);
                        });
                    }
                }
            }

            env.mutate(|mc, env| {
                let res = env.proj.borrow_mut(mc).step(mc);
                if let ProjectStep::Error { error, proc } = &res {
                    DART_COMMANDS.lock().unwrap().push(DartCommand::Stderr { msg: format!("runtime error in entity {:?}: {:?}", proc.get_call_stack().last().unwrap().entity.borrow().name, error.cause) });
                }
                idle_sleeper.consume(&res);
            });
        }
    });

    DART_COMMANDS.lock().unwrap().push(DartCommand::AddButton { key: DartRequestKey::new(), info: ButtonInfo {
        id: "test-1".into(),
        x: 10.0,
        y: 10.0,
        width: 50.0,
        height: 50.0,
        back_color: ColorInfo { a: 255, r: 255, g: 100, b: 100 },
        fore_color: ColorInfo { a: 255, r: 100, g: 255, b: 100 },
        text: "merp derp this is going to be a big thing of text that will go off the thing and be really long and stuff haha".into(),
        event: None,
        font_size: 1.0,
        style: ButtonStyleInfo::Rectangle,
        landscape: false,
    }});
    DART_COMMANDS.lock().unwrap().push(DartCommand::AddButton { key: DartRequestKey::new(), info: ButtonInfo {
        id: "test-2".into(),
        x: 20.0,
        y: 40.0,
        width: 20.0,
        height: 30.0,
        back_color: ColorInfo { a: 255, r: 50, g: 100, b: 100 },
        fore_color: ColorInfo { a: 255, r: 200, g: 100, b: 100 },
        text: "merp derp this is going to be a big thing of text that will go off the thing and be really long and stuff haha".into(),
        event: None,
        font_size: 1.0,
        style: ButtonStyleInfo::Rectangle,
        landscape: false,
    }});
}

pub fn send_command(cmd: RustCommand) {
    RUST_COMMANDS.lock().unwrap().push(cmd);
}
pub fn recv_commands() -> Vec<DartCommand> {
    mem::take(&mut *DART_COMMANDS.lock().unwrap())
}

pub fn complete_request(key: DartRequestKey, result: RequestResult) {
    let key = PENDING_REQUESTS.lock().unwrap().remove(&key);
    if let Some(key) = key {
        key.complete(result.into_result().map(|x| Intermediate::Json(x.into_json())));
    }
}
