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
use netsblox_vm::real_time::UtcOffset;
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
    // important: this can't be the same scheme as the default remote netsblox scheme or there will be collision failures when using both defaults
    format!("ct-{}", CONTROL_COUNTER.fetch_add(1, MemOrder::Relaxed).wrapping_add(1))
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
pub enum ImageFitInfo {
    Fit, Zoom, Stretch,
}
#[derive(Clone, Copy, Debug)]
pub enum TouchpadStyleInfo {
    Rectangle, Square,
}
#[derive(Clone, Copy, Debug)]
pub enum SliderStyleInfo {
    Slider, Progress,
}
#[derive(Clone, Copy, Debug)]
pub enum ToggleStyleInfo {
    Switch, Checkbox,
}
#[derive(Clone, Copy, Debug)]
pub struct ColorInfo {
    pub a: u8,
    pub r: u8,
    pub g: u8,
    pub b: u8,
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
pub struct TextFieldInfo {
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
    pub landscape: bool,
    pub readonly: bool,
    pub align: TextAlignInfo,
}
#[derive(Clone, Debug)]
pub struct JoystickInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub event: Option<String>,
    pub color: ColorInfo,
    pub landscape: bool,
}
#[derive(Clone, Debug)]
pub struct TouchpadInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub event: Option<String>,
    pub color: ColorInfo,
    pub style: TouchpadStyleInfo,
    pub landscape: bool,
}
#[derive(Clone, Debug)]
pub struct SliderInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub event: Option<String>,
    pub color: ColorInfo,
    pub value: f64,
    pub style: SliderStyleInfo,
    pub landscape: bool,
    pub readonly: bool,
}
#[derive(Clone, Debug)]
pub struct ToggleInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub text: String,
    pub style: ToggleStyleInfo,
    pub event: Option<String>,
    pub checked: bool,
    pub fore_color: ColorInfo,
    pub back_color: ColorInfo,
    pub font_size: f64,
    pub landscape: bool,
    pub readonly: bool,
}
#[derive(Clone, Debug)]
pub struct ImageDisplayInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub event: Option<String>,
    pub readonly: bool,
    pub landscape: bool,
    pub fit: ImageFitInfo,
}

pub enum RustCommand {
    SetProject { xml: String },
    Start,
    Stop,
    InjectMessage { msg_type: String, values: Vec<(String, SimpleValue)> },
}

#[derive(Clone, Copy, PartialOrd, Ord, PartialEq, Eq, Debug)]
pub struct DartRequestKey {
    pub value: usize,
}
impl DartRequestKey {
    fn new(key: RequestKey<C>) -> Self {
        let res = Self { value: KEY_COUNTER.fetch_add(1, MemOrder::Relaxed) };
        PENDING_REQUESTS.lock().unwrap().insert(res, key);
        res
    }
}

#[derive(Clone, Debug)]
pub enum DartCommand {
    Stdout { msg: String },
    Stderr { msg: String },

    ClearControls { key: DartRequestKey },
    RemoveControl { key: DartRequestKey, id: String },

    AddLabel { key: DartRequestKey, info: LabelInfo },
    AddButton { key: DartRequestKey, info: ButtonInfo },
    AddTextField { key: DartRequestKey, info: TextFieldInfo },
    AddJoystick { key: DartRequestKey, info: JoystickInfo },
    AddTouchpad { key: DartRequestKey, info: TouchpadInfo },
    AddSlider { key: DartRequestKey, info: SliderInfo },
    AddToggle { key: DartRequestKey, info: ToggleInfo },
    AddImageDisplay { key: DartRequestKey, info: ImageDisplayInfo },

    GetText { key: DartRequestKey, id: String },
    SetText { key: DartRequestKey, id: String, value: String },
    GetLevel { key: DartRequestKey, id: String },
    SetLevel { key: DartRequestKey, id: String, value: f64 },
    GetToggleState { key: DartRequestKey, id: String },
    SetToggleState { key: DartRequestKey, id: String, value: bool },
    GetImage { key: DartRequestKey, id: String },
    SetImage { key: DartRequestKey, id: String, value: Vec<u8> },
    GetPosition { key: DartRequestKey, id: String },
    IsPressed { key: DartRequestKey, id: String },

    GetAccelerometer { key: DartRequestKey },
    GetLinearAccelerometer { key: DartRequestKey },
    GetGyroscope { key: DartRequestKey },
    GetMagnetometer { key: DartRequestKey },
    GetGravity { key: DartRequestKey },
    GetPressure { key: DartRequestKey },
    GetRelativeHumidity { key: DartRequestKey },
}

pub enum SimpleValue {
    Bool(bool),
    Number(f64),
    String(String),
    List(Vec<SimpleValue>),
    Image(Vec<u8>),
}
impl SimpleValue {
    fn into_json(self) -> Json {
        match self {
            SimpleValue::Bool(x) => Json::Bool(x),
            SimpleValue::Number(x) => json!(x),
            SimpleValue::String(x) => Json::String(x),
            SimpleValue::List(x) => Json::Array(x.into_iter().map(SimpleValue::into_json).collect()),
            SimpleValue::Image(_) => panic!("attempt to transfer image as json"),
        }
    }
    fn into_intermediate(self) -> Intermediate {
        match self {
            SimpleValue::Bool(x) => Intermediate::Json(Json::Bool(x)),
            SimpleValue::Number(x) => Intermediate::Json(json!(x)),
            SimpleValue::String(x) => Intermediate::Json(Json::String(x)),
            SimpleValue::List(x) => Intermediate::Json(Json::Array(x.into_iter().map(SimpleValue::into_json).collect())),
            SimpleValue::Image(x) => Intermediate::Image(x),
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

pub fn initialize(utc_offset_in_seconds: i32) {
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
                fn is_local_id<'gc, C: CustomTypes<S>, S: System<C>>(s: &Value<'gc, C, S>) -> bool {
                    s.to_string().ok().map(|x| x.chars().all(|x| x == '0')).unwrap_or(false)
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
                    ($n:ident := $e:expr => TouchpadStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "rectangle" => TouchpadStyleInfo::Rectangle,
                            "square" => TouchpadStyleInfo::Square,
                            x => {
                                key.complete(Err(format!("'{}': unknown touchpad style '{}'", stringify!($n), x)));
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
                    ($n:ident := $e:expr => ImageFitInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "fit" => ImageFitInfo::Fit,
                            "zoom" => ImageFitInfo::Zoom,
                            "stretch" => ImageFitInfo::Stretch,
                            x => {
                                key.complete(Err(format!("'{}': unknown image fit mode '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => SliderStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "slider" => SliderStyleInfo::Slider,
                            "progress" => SliderStyleInfo::Progress,
                            x => {
                                key.complete(Err(format!("'{}': unknown slider style '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => ToggleStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "switch" => ToggleStyleInfo::Switch,
                            "checkbox" => ToggleStyleInfo::Checkbox,
                            x => {
                                key.complete(Err(format!("'{}': unknown toggle style '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => Image) => {
                        match &$e {
                            Value::Image(x) => (**x).clone(),
                            x => {
                                key.complete(Err(format!("{}': expected image, got {:?}", stringify!($n), x.get_type())));
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
                        "getSensors" => {
                            if args.len() != 0 {
                                return RequestStatus::UseDefault { key, request };
                            }
                            key.complete(Ok(Intermediate::Json(json!([
                                "gravity", "gyroscope", "orientation", "accelerometer", "magneticField", "linearAcceleration", "lightLevel",
                                "microphoneLevel", "proximity", "stepCount", "location", "pressure", "temperature", "humidity",
                            ]))));
                            RequestStatus::Handled
                        }
                        "getColor" => {
                            if args.len() != 4 {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let r = parse!(red := args[0].1 => f64) as u8;
                            let g = parse!(green := args[1].1 => f64) as u8;
                            let b = parse!(blue := args[2].1 => f64) as u8;
                            let a = parse!(alpha := args[3].1 => f64) as u8;

                            let encoded = ((a as i32) << 24) | ((r as i32) << 16) | ((g as i32) << 8) | b as i32;
                            key.complete(Ok(Intermediate::Json(json!(encoded))));
                            RequestStatus::Handled
                        }
                        "setCredentials" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }
                            key.complete(Ok(Intermediate::Json(json!("OK"))));
                            RequestStatus::Handled
                        }
                        "authenticate" | "listenToGUI" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }
                            key.complete(Ok(Intermediate::Json(json!("OK"))));
                            RequestStatus::Handled
                        }
                        "clearControls" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            CONTROL_COUNTER.store(0, MemOrder::Relaxed);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::ClearControls { key });
                            RequestStatus::Handled
                        }
                        "removeControl" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::RemoveControl { key, id });
                            RequestStatus::Handled
                        }
                        "addButton" => {
                            if args.len() != 7 || !is_local_id(&args[0].1) {
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

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddButton { key, info: ButtonInfo {
                                id, x, y, width, height, text, landscape, back_color, fore_color, font_size, event, style,
                            }});
                            RequestStatus::Handled
                        }
                        "addLabel" => {
                            if args.len() != 5 || !is_local_id(&args[0].1) {
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

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddLabel { key, info: LabelInfo {
                                x, y, text, id, color, font_size, landscape, align,
                            }});
                            RequestStatus::Handled
                        }
                        "addTextField" => {
                            if args.len() != 6 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let width = parse!(width := args[3].1 => f64);
                            let height = parse!(height := args[4].1 => f64);
                            let options = parse!(options := args[5].1 => { id, event, text, color, textColor, readonly, fontSize, align, landscape });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let back_color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                            let fore_color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(BLACK);
                            let text = parse!(text := options.get("text") => Option<String>).unwrap_or_default();
                            let event = parse!(event := options.get("event") => Option<String>);
                            let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(false);
                            let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                            let align = parse!(align := options.get("align") => Option<TextAlignInfo>).unwrap_or(TextAlignInfo::Left);
                            let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddTextField { key, info: TextFieldInfo {
                                id, x, y, width, height, back_color, fore_color, text, event, font_size, landscape, readonly, align,
                            }});
                            RequestStatus::Handled
                        }
                        "addJoystick" => {
                            if args.len() != 5 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let width = parse!(width := args[3].1 => f64);
                            let options = parse!(options := args[4].1 => { id, event, color, landscape });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let event = parse!(event := options.get("event") => Option<String>);
                            let color = parse!(event := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                            let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddJoystick { key, info: JoystickInfo {
                                x, y, width, id, event, color, landscape,
                            }});
                            RequestStatus::Handled
                        }
                        "addTouchpad" => {
                            if args.len() != 6 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let width = parse!(width := args[3].1 => f64);
                            let height = parse!(height := args[4].1 => f64);
                            let options = parse!(options := args[5].1 => { id, event, color, style, landscape });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let event = parse!(event := options.get("event") => Option<String>);
                            let color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                            let style = parse!(style := options.get("style") => Option<TouchpadStyleInfo>).unwrap_or(TouchpadStyleInfo::Rectangle);
                            let landscape = parse!(style := options.get("landscape") => Option<bool>).unwrap_or(false);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddTouchpad { key, info: TouchpadInfo {
                                x, y, width, height, id, event, color, style, landscape,
                            }});
                            RequestStatus::Handled
                        }
                        "addSlider" => {
                            if args.len() != 5 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let width = parse!(width := args[3].1 => f64);
                            let options = parse!(options := args[4].1 => { id, event, color, value, style, landscape, readonly });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let event = parse!(event := options.get("event") => Option<String>);
                            let color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                            let value = parse!(value := options.get("value") => Option<f64>).unwrap_or(0.0);
                            let style = parse!(style := options.get("style") => Option<SliderStyleInfo>).unwrap_or(SliderStyleInfo::Slider);
                            let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                            let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(false);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddSlider { key, info: SliderInfo {
                                x, y, width, id, event, color, value, style, landscape, readonly,
                            }});
                            RequestStatus::Handled
                        }
                        "addToggle" => {
                            if args.len() != 5 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let text = parse!(text := args[3].1 => String);
                            let options = parse!(options := args[4].1 => { style, id, event, checked, color, textColor, fontSize, landscape, readonly });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let style = parse!(style := options.get("style") => Option<ToggleStyleInfo>).unwrap_or(ToggleStyleInfo::Switch);
                            let event = parse!(event := options.get("event") => Option<String>);
                            let checked = parse!(checked := options.get("checked") => Option<bool>).unwrap_or(false);
                            let back_color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                            let fore_color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(BLACK);
                            let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                            let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                            let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(false);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddToggle { key, info: ToggleInfo {
                                x, y, text, id, style, event, checked, fore_color, back_color, font_size, landscape, readonly,
                            }});
                            RequestStatus::Handled
                        }
                        "addImageDisplay" => {
                            if args.len() != 6 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let x = parse!(x := args[1].1 => f64);
                            let y = parse!(y := args[2].1 => f64);
                            let width = parse!(width := args[3].1 => f64);
                            let height = parse!(height := args[4].1 => f64);
                            let options = parse!(options := args[5].1 => { id, event, readonly, landscape, fit });
                            let id = parse!(id := options.get("id") => Option<String>).unwrap_or_else(new_control_id);
                            let event = parse!(event := options.get("event") => Option<String>);
                            let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(true);
                            let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                            let fit = parse!(fit := options.get("fit") => Option<ImageFitInfo>).unwrap_or(ImageFitInfo::Fit);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::AddImageDisplay { key, info: ImageDisplayInfo {
                                id, x, y, width, height, event, readonly, landscape, fit,
                            }});
                            RequestStatus::Handled
                        }
                        "getText" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetText { key, id });
                            RequestStatus::Handled
                        }
                        "setText" => {
                            if args.len() != 3 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);
                            let value = parse!(text := args[2].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::SetText { key, id, value });
                            RequestStatus::Handled
                        }
                        "isPressed" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::IsPressed { key, id });
                            RequestStatus::Handled
                        }
                        "getPosition" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetPosition { key, id });
                            RequestStatus::Handled
                        }
                        "getImage" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetImage { key, id });
                            RequestStatus::Handled
                        }
                        "setImage" => {
                            if args.len() != 3 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);
                            let value = parse!(img := args[2].1 => Image);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::SetImage { key, id, value });
                            RequestStatus::Handled
                        }
                        "getLevel" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetLevel { key, id });
                            RequestStatus::Handled
                        }
                        "setLevel" => {
                            if args.len() != 3 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);
                            let value = parse!(value := args[2].1 => f64);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::SetLevel { key, id, value });
                            RequestStatus::Handled
                        }
                        "getToggleState" => {
                            if args.len() != 2 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetToggleState { key, id });
                            RequestStatus::Handled
                        }
                        "setToggleState" => {
                            if args.len() != 3 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let id = parse!(id := args[1].1 => String);
                            let value = parse!(state := args[2].1 => bool);

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::SetToggleState { key, id, value });
                            RequestStatus::Handled
                        }
                        "getAccelerometer" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetAccelerometer { key });
                            RequestStatus::Handled
                        }
                        "getLinearAcceleration" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetLinearAccelerometer { key });
                            RequestStatus::Handled
                        }
                        "getGyroscope" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetGyroscope { key });
                            RequestStatus::Handled
                        }
                        "getMagneticField" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetMagnetometer { key });
                            RequestStatus::Handled
                        }
                        "getGravity" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetGravity { key });
                            RequestStatus::Handled
                        }
                        "getPressure" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetPressure { key });
                            RequestStatus::Handled
                        }
                        "getRelativeHumidity" => {
                            if args.len() != 1 || !is_local_id(&args[0].1) {
                                return RequestStatus::UseDefault { key, request };
                            }

                            let key = DartRequestKey::new(key);
                            send_dart_command(DartCommand::GetRelativeHumidity { key });
                            RequestStatus::Handled
                        }
                        _ => RequestStatus::UseDefault { key, request },
                    }
                    _ => RequestStatus::UseDefault { key, request },
                }
            })),
        };
        let utc_offset = UtcOffset::from_whole_seconds(utc_offset_in_seconds).unwrap_or(UtcOffset::UTC);
        let system = Rc::new(StdSystem::new(SERVER_URL.to_owned(), None, config, utc_offset));
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
                    RustCommand::Start => env.mutate(|mc, env| {
                        env.proj.borrow_mut(mc).input(mc, Input::Start);
                    }),
                    RustCommand::Stop => env.mutate(|mc, env| {
                        env.proj.borrow_mut(mc).input(mc, Input::Stop);
                    }),
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
        key.complete(result.into_result().map(SimpleValue::into_intermediate));
    }
}
