use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering as MemOrder};
use std::collections::BTreeMap;
use std::time::Duration;
use std::sync::Mutex;
use std::rc::Rc;
use std::{mem, thread};

use netsblox_vm::project::{Project, IdleAction, ProjectStep, Input};
use netsblox_vm::std_system::{StdSystem, RequestKey};
use netsblox_vm::bytecode::{ByteCode, Locations};
use netsblox_vm::runtime::{CustomTypes, GetType, EntityKind, IntermediateType, ErrorCause, Value, FromAstError, Config, Command, Request, CommandStatus, RequestStatus, Key, System};
use netsblox_vm::gc::{Gc, RefLock, Collect, Arena, Rootable, Mutation};
use netsblox_vm::json::{Json, json};
use netsblox_vm::ast;

use flutter_rust_bridge::StreamSink;

const SERVER_URL: &'static str = "https://editor.netsblox.org";
const IDLE_SLEEP_THRESH: usize = 256;
const IDLE_SLEEP_TIME: Duration = Duration::from_millis(1);

const BLUE: ColorInfo = ColorInfo { a: 255, r: 66, g: 135, b: 245 };
const BLACK: ColorInfo = ColorInfo { a: 255, r: 0, g: 0, b: 0 };
const WHITE: ColorInfo = ColorInfo { a: 255, r: 255, g: 255, b: 255 };

static INITIALIZED: AtomicBool = AtomicBool::new(false);
static DART_COMMANDS: Mutex<DartCommandPipe> = Mutex::new(DartCommandPipe { sink: None, backlog: Vec::new() });
static RUST_COMMANDS: Mutex<Vec<RustCommand>> = Mutex::new(Vec::new());
static PENDING_REQUESTS: Mutex<BTreeMap<DartRequestKey, RequestKey<C>>> = Mutex::new(BTreeMap::new());
static KEY_COUNTER: AtomicUsize = AtomicUsize::new(0);
static CONTROL_COUNTER: AtomicUsize = AtomicUsize::new(0);

struct DartCommandPipe {
    sink: Option<StreamSink<DartCommand>>,
    backlog: Vec<DartCommand>,
}

fn new_control_id() -> String {
    format!("ctrl-{}", CONTROL_COUNTER.fetch_add(1, MemOrder::Relaxed).wrapping_add(1))
}

fn send_dart_command(cmd: DartCommand) {
    let mut commands = DART_COMMANDS.lock().unwrap();
    let handled = commands.sink.as_ref().map(|x| x.add(cmd.clone())).unwrap_or(false);
    if !handled {
        println!("backlogging cmd {cmd:?}");
        commands.backlog.push(cmd);
    }
}

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

#[derive(Clone, Copy, Debug)]
pub enum ButtonStyleInfo {
    Rectangle, Ellipse, Square, Circle,
}
#[derive(Clone, Copy, Debug)]
pub enum TextAlignInfo {
    Left, Center, Right,
}

#[derive(Clone, Copy, Debug)]
pub struct ColorInfo {
    pub a: u8,
    pub r: u8,
    pub g: u8,
    pub b: u8,
}
#[derive(Clone, Debug)]
pub struct ButtonInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub back_color: ColorInfo,
    pub fore_color: ColorInfo,
    pub text: String,
    pub event: Option<String>,
    pub font_size: f64,
    pub style: ButtonStyleInfo,
    pub landscape: bool,
}
#[derive(Clone, Debug)]
pub struct LabelInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub color: ColorInfo,
    pub text: String,
    pub font_size: f64,
    pub align: TextAlignInfo,
    pub landscape: bool,
}

pub enum RustCommand {
    SetProject { xml: String },
    Start,
    InjectMessage { msg_type: String, values: Vec<(String, SimpleValue)> },
}

#[derive(Clone, Copy, PartialOrd, Ord, PartialEq, Eq, Debug)]
pub struct DartRequestKey {
    pub value: usize,
}
impl DartRequestKey {
    fn new() -> Self {
        Self { value: KEY_COUNTER.fetch_add(1, MemOrder::Relaxed) }
    }
}

#[derive(Clone, Debug)]
pub enum DartCommand {
    Stdout { msg: String },
    Stderr { msg: String },
    ClearControls,
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
                                Ok(x) => send_dart_command(DartCommand::Stdout { msg: x.into_owned() }),
                                Err(e) => send_dart_command(DartCommand::Stderr { msg: format!("print {e:?}") }),
                            }
                        }
                    }
                    _ => return CommandStatus::UseDefault { key, command },
                }
                key.complete(Ok(()));
                CommandStatus::Handled
            })),
            request: Some(Rc::new(move |_, _, key, request, _| {
                fn is_local_id(s: &str) -> bool {
                    s.chars().all(|x| x == '0')
                }
                fn parse_options<'gc, C: CustomTypes<S>, S: System<C>>(name: &str, opts: &Value<'gc, C, S>, allowed: &[&str]) -> Result<BTreeMap<String, Value<'gc, C, S>>, String> {
                    let mut res = BTreeMap::new();
                    match opts {
                        Value::String(x) => match x.is_empty() {
                            true => (),
                            false => return Err(format!("'{name}' must be a list of lists")),
                        }
                        Value::List(x) => for x in x.borrow().iter() {
                            match x {
                                Value::List(x) => {
                                    let x = x.borrow();
                                    if x.len() != 2 {
                                        return Err(format!("'{name}' must be a list of pairs (length 2 lists)"));
                                    }
                                    let k = match x[0].to_string() {
                                        Ok(x) => x.into_owned(),
                                        Err(_) => return Err(format!("'{name}' keys must be strings")),
                                    };
                                    if !allowed.iter().any(|x| **x == k) {
                                        return Err(format!("'{name}': unknown option '{k}'"));
                                    }
                                    if res.insert(k.clone(), x[1].clone()).is_some() {
                                        return Err(format!("'{name}': option '{k}' was already specified"));
                                    }
                                }
                                _ => return Err(format!("'{name}' must be a list of lists")),
                            }
                        }
                        _ => return Err(format!("{name}' must be a list of lists")),
                    }
                    Ok(res)
                }
                macro_rules! parse {
                    ($n:ident := $e:expr => bool) => {
                        match &$e {
                            Value::Bool(x) => *x,
                            Value::String(x) if **x == "true" => true,
                            Value::String(x) if **x == "false" => false,
                            x => {
                                key.complete(Err(format!("'{}': expected bool, got {:?}", stringify!($n), x.get_type())));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => f64) => {
                        match $e.to_number() {
                            Ok(x) => x.get(),
                            Err(x) => {
                                key.complete(Err(format!("'{}': expected number, got {:?}", stringify!($n), x.got)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => String) => {
                        match $e.to_string() {
                            Ok(x) => x.into_owned(),
                            Err(x) => {
                                key.complete(Err(format!("'{}': expected string, got {:?}", stringify!($n), x.got)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => ButtonStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "rectangle" => ButtonStyleInfo::Rectangle,
                            "ellipse" => ButtonStyleInfo::Ellipse,
                            "square" => ButtonStyleInfo::Square,
                            "circle" => ButtonStyleInfo::Circle,
                            x => {
                                key.complete(Err(format!("'{}': unknown button style '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => TextAlignInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "left" => TextAlignInfo::Left,
                            "right" => TextAlignInfo::Right,
                            "center" => TextAlignInfo::Center,
                            x => {
                                key.complete(Err(format!("'{}': unknown text align '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => ColorInfo) => {{
                        let v = parse!($n := $e => f64) as i32 as u32;
                        let a = (v >> 24) as u8;
                        let r = (v >> 16) as u8;
                        let g = (v >> 8) as u8;
                        let b = v as u8;
                        ColorInfo { a, r, g, b }
                    }};
                    ($n:ident := $e:expr => {$($f:ident),*}) => {
                        match parse_options(stringify!($n), &$e, &[$(stringify!($f)),*]) {
                            Ok(x) => x,
                            Err(e) => {
                                key.complete(Err(e));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => Option<$t:ident>) => {
                        match &$e {
                            Some(x) => Some(parse!($n := x => $t)),
                            None => None,
                        }
                    };
                }
                match &request {
                    Request::Rpc { service, rpc, args } if service == "PhoneIoT" => match rpc.as_str() {
                        "getColor" => {
                            if args.len() != 4 {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let r = parse!(r := args[0].1 => f64) as u8;
                            let g = parse!(g := args[1].1 => f64) as u8;
                            let b = parse!(b := args[2].1 => f64) as u8;
                            let a = parse!(a := args[3].1 => f64) as u8;

                            let encoded = ((a as i32) << 24) | ((r as i32) << 16) | ((g as i32) << 8) | b as i32;
                            key.complete(Ok(Intermediate::Json(json!(encoded))));
                            RequestStatus::Handled
                        }
                        "clearControls" => {
                            if args.len() != 1 || !args[0].1.to_string().ok().map(|x| is_local_id(&x)).unwrap_or(false) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            send_dart_command(DartCommand::ClearControls);
                            CONTROL_COUNTER.store(0, MemOrder::Relaxed);
                            key.complete(Ok(Intermediate::Json(json!("OK"))));
                            RequestStatus::Handled
                        }
                        "addButton" => {
                            if args.len() != 7 || !args[0].1.to_string().ok().map(|x| is_local_id(&x)).unwrap_or(false) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let width = parse!(width := args[3].1 => f64);
                            let height = parse!(height := args[4].1 => f64);
                            let text = parse!(text := args[5].1 => String);
                            let options = parse!(options := args[6].1 => { id, event, style, color, textColor, landscape, fontSize });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                            let back_color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                            let fore_color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(WHITE);
                            let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                            let event = parse!(event := options.get("event") => Option<String>);
                            let style = parse!(style := options.get("style") => Option<ButtonStyleInfo>).unwrap_or(ButtonStyleInfo::Rectangle);

                            let dart_key = DartRequestKey::new();
                            PENDING_REQUESTS.lock().unwrap().insert(dart_key, key);
                            send_dart_command(DartCommand::AddButton { key: dart_key, info: ButtonInfo {
                                id, x, y, width, height, text, landscape, back_color, fore_color, font_size, event, style,
                            }});
                            RequestStatus::Handled
                        }
                        "addLabel" => {
                            if args.len() != 5 || !args[0].1.to_string().ok().map(|x| is_local_id(&x)).unwrap_or(false) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let text = parse!(text := args[3].1 => String);
                            let options = parse!(options := args[4].1 => { id, textColor, align, fontSize, landscape });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(BLACK);
                            let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                            let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                            let align = parse!(align := options.get("align") => Option<TextAlignInfo>).unwrap_or(TextAlignInfo::Left);

                            let dart_key = DartRequestKey::new();
                            PENDING_REQUESTS.lock().unwrap().insert(dart_key, key);
                            send_dart_command(DartCommand::AddLabel { key: dart_key, info: LabelInfo {
                                x, y, text, id, color, font_size, landscape, align,
                            }});
                            RequestStatus::Handled
                        }
                        _ => RequestStatus::UseDefault { key, request },
                    }
                    _ => RequestStatus::UseDefault { key, request },
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
                                    send_dart_command(DartCommand::Stdout { msg: "loaded project".into() });
                                }
                                Err(e) => send_dart_command(DartCommand::Stderr { msg: format!("project load error: {e:?}") }),
                            }
                            x => send_dart_command(DartCommand::Stderr { msg: format!("project load error: expected 1 role, got {}", x.len()) } ),
                        }
                        Err(e) => send_dart_command(DartCommand::Stderr { msg: format!("project load error: {e:?}") }),
                    }
                    RustCommand::Start => {
                        env.mutate(|mc, env| {
                            env.proj.borrow_mut(mc).input(Input::Start);
                        });
                    }
                    RustCommand::InjectMessage { msg_type, values } => system.inject_message(msg_type, values.into_iter().map(|x| (x.0, x.1.into_json())).collect()),
                }
            }

            env.mutate(|mc, env| {
                let res = env.proj.borrow_mut(mc).step(mc);
                if let ProjectStep::Error { error, proc } = &res {
                    send_dart_command(DartCommand::Stderr { msg: format!("runtime error in entity {:?}: {:?}", proc.get_call_stack().last().unwrap().entity.borrow().name, error.cause) });
                }
                idle_sleeper.consume(&res);
            });
        }
    });

    send_dart_command(DartCommand::AddButton { key: DartRequestKey::new(), info: ButtonInfo {
        id: "test-1".into(),
        x: 10.0,
        y: 10.0,
        width: 50.0,
        height: 50.0,
        back_color: ColorInfo { a: 255, r: 255, g: 100, b: 100 },
        fore_color: ColorInfo { a: 255, r: 100, g: 255, b: 100 },
        text: "1 merp derp this is going to be a big thing of text that will go off the thing and be really long and stuff haha".into(),
        event: None,
        font_size: 1.0,
        style: ButtonStyleInfo::Ellipse,
        landscape: false,
    }});
    send_dart_command(DartCommand::AddButton { key: DartRequestKey::new(), info: ButtonInfo {
        id: "test-2".into(),
        x: 20.0,
        y: 40.0,
        width: 20.0,
        height: 70.0,
        back_color: ColorInfo { a: 255, r: 50, g: 100, b: 100 },
        fore_color: ColorInfo { a: 255, r: 200, g: 100, b: 100 },
        text: "2 merp derp this is going to be a big thing of text that will go off the thing and be really long and stuff haha".into(),
        event: None,
        font_size: 2.0,
        style: ButtonStyleInfo::Circle,
        landscape: false,
    }});
    send_dart_command(DartCommand::AddButton { key: DartRequestKey::new(), info: ButtonInfo {
        id: "test-3".into(),
        x: 55.0,
        y: 25.0,
        width: 40.0,
        height: 30.0,
        back_color: ColorInfo { a: 255, r: 20, g: 100, b: 20 },
        fore_color: ColorInfo { a: 255, r: 200, g: 200, b: 100 },
        text: "3 merp derp this is going to be a big thing of text that will go off the thing and be really long and stuff haha".into(),
        event: None,
        font_size: 2.0,
        style: ButtonStyleInfo::Rectangle,
        landscape: true,
    }});
    send_dart_command(DartCommand::AddLabel { key: DartRequestKey::new(), info: LabelInfo {
        id: "test-4".into(),
        x: 20.0,
        y: 5.0,
        color: ColorInfo { a: 255, r: 20, g: 100, b: 20 },
        text: "4 shorter message test...".into(),
        font_size: 1.0,
        align: TextAlignInfo::Left,
        landscape: false,
    }});
    send_dart_command(DartCommand::AddLabel { key: DartRequestKey::new(), info: LabelInfo {
        id: "test-5".into(),
        x: 20.0,
        y: 7.0,
        color: ColorInfo { a: 255, r: 20, g: 100, b: 20 },
        text: "5 shorter message test...".into(),
        font_size: 1.0,
        align: TextAlignInfo::Center,
        landscape: true,
    }});
    send_dart_command(DartCommand::AddLabel { key: DartRequestKey::new(), info: LabelInfo {
        id: "test-6".into(),
        x: 20.0,
        y: 9.0,
        color: ColorInfo { a: 255, r: 20, g: 100, b: 20 },
        text: "6 shorter message test...".into(),
        font_size: 2.0,
        align: TextAlignInfo::Right,
        landscape: false,
    }});
}

pub fn send_command(cmd: RustCommand) {
    RUST_COMMANDS.lock().unwrap().push(cmd);
}
pub fn recv_commands(sink: StreamSink<DartCommand>) {
    let backlog = {
        let mut commands = DART_COMMANDS.lock().unwrap();
        commands.sink = Some(sink.clone());
        mem::take(&mut commands.backlog)
    };
    println!("retrying backlogged commands...");
    for cmd in backlog {
        send_dart_command(cmd);
    }
}

pub fn complete_request(key: DartRequestKey, result: RequestResult) {
    let key = PENDING_REQUESTS.lock().unwrap().remove(&key);
    if let Some(key) = key {
        key.complete(result.into_result().map(|x| Intermediate::Json(x.into_json())));
    }
}
