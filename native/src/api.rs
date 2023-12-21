use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering as MemOrder};
use std::collections::BTreeMap;
use std::time::Duration;
use std::sync::{Arc, Mutex};
use std::rc::Rc;
use std::{mem, thread};

use netsblox_vm::project::{Project, IdleAction, ProjectStep, Input};
use netsblox_vm::std_system::StdSystem;
use netsblox_vm::std_util::{AsyncKey, Clock};
use netsblox_vm::bytecode::{ByteCode, Locations};
use netsblox_vm::runtime::{CustomTypes, GetType, EntityKind, ProcessKind, Value, FromAstError, Config, Command, Request, CommandStatus, RequestStatus, Key, System, SimpleValue, Number, Image, Audio, Precision};
use netsblox_vm::gc::{Gc, RefLock, Collect, Arena, Rootable, Mutation};
use netsblox_vm::real_time::UtcOffset;
use netsblox_vm::json::json;
use netsblox_vm::compact_str::{CompactString, format_compact};
use netsblox_vm::ast;

use flutter_rust_bridge::{StreamSink, IntoDart, rust2dart::IntoIntoDart};

const SERVER_URL: &str = "https://cloud.netsblox.org";
const STEPS_PER_IO_ITER: usize = 16;
const IDLE_SLEEP_THRESH: usize = 256;
const IDLE_SLEEP_TIME: Duration = Duration::from_millis(1);
const CLOCK_INTERVAL: Duration = Duration::from_millis(10);
const COLLECT_INTERVAL: Duration = Duration::from_secs(60);

const BLUE: ColorInfo = ColorInfo { a: 255, r: 66, g: 135, b: 245 };
const BLACK: ColorInfo = ColorInfo { a: 255, r: 0, g: 0, b: 0 };
const WHITE: ColorInfo = ColorInfo { a: 255, r: 255, g: 255, b: 255 };

static INITIALIZED: AtomicBool = AtomicBool::new(false);
static DART_COMMANDS: Mutex<DartPipe<DartCommand>> = Mutex::new(DartPipe::new());
static RUST_COMMANDS: Mutex<Vec<RustCommand>> = Mutex::new(Vec::new());
static PENDING_REQUESTS: Mutex<BTreeMap<DartRequestKey, AsyncKey<Result<SimpleValue, CompactString>>>> = Mutex::new(BTreeMap::new());
static PENDING_COMMANDS: Mutex<BTreeMap<DartCommandKey, AsyncKey<Result<(), CompactString>>>> = Mutex::new(BTreeMap::new());
static KEY_COUNTER: AtomicUsize = AtomicUsize::new(0);
static CONTROL_COUNTER: AtomicUsize = AtomicUsize::new(0);

struct DartPipe<T> {
    sink: Option<StreamSink<T>>,
    backlog: Vec<T>,
}
impl<T: Clone + std::fmt::Debug + IntoDart + IntoIntoDart<T>> DartPipe<T> {
    const fn new() -> Self {
        DartPipe { sink: None, backlog: Vec::new() }
    }
    fn send(&mut self, val: T) {
        let handled = self.sink.as_ref().map(|x| x.add(val.clone())).unwrap_or(false);
        if !handled {
            println!("backlogging cmd {val:?}");
            self.backlog.push(val);
        }
    }
    fn retry_backlog(&mut self, sink: StreamSink<T>) {
        println!("retrying backlogged commands...");
        self.sink = Some(sink);
        for val in mem::take(&mut self.backlog) {
            self.send(val);
        }
    }
}

struct PauseController {
    value: bool,
}
impl PauseController {
    fn new(value: bool) -> Self {
        Self { value }
    }
    fn is_paused(&self) -> bool {
        self.value
    }
    fn set_paused(&mut self, value: bool) {
        self.value = value;
        DART_COMMANDS.lock().unwrap().send(DartCommand::UpdatePaused { value });
    }
    fn toggle_paused(&mut self) {
        self.set_paused(!self.value);
    }
}

fn new_control_id() -> String {
    // important: this can't be the same scheme as the default remote netsblox scheme or there will be collision failures when using both defaults
    format!("ct-{}", CONTROL_COUNTER.fetch_add(1, MemOrder::Relaxed).wrapping_add(1))
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
struct ProcessState;
impl From<ProcessKind<'_, '_, C, StdSystem<C>>> for ProcessState {
    fn from(_: ProcessKind<'_, '_, C, StdSystem<C>>) -> Self {
        ProcessState
    }
}

struct C;
impl CustomTypes<StdSystem<C>> for C {
    type NativeValue = NativeValue;
    type Intermediate = SimpleValue;

    type EntityState = EntityState;
    type ProcessState = ProcessState;

    fn from_intermediate<'gc>(mc: &Mutation<'gc>, value: Self::Intermediate) -> Value<'gc, C, StdSystem<C>> {
        Value::from_simple(mc, value)
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
    let (bytecode, init_info, locs, _) = ByteCode::compile(role)?;
    Ok(EnvArena::new(|mc| {
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
pub struct RadioButtonInfo {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub text: String,
    pub group: String,
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
#[derive(Clone, Debug, Default)]
pub struct SensorUpdateInfo {
    pub gravity: Option<f64>,
    pub gyroscope: Option<f64>,
    pub orientation: Option<f64>,
    pub accelerometer: Option<f64>,
    pub magnetic_field: Option<f64>,
    pub linear_acceleration: Option<f64>,
    pub light_level: Option<f64>,
    pub microphone_level: Option<f64>,
    pub proximity: Option<f64>,
    pub step_count: Option<f64>,
    pub location: Option<f64>,
    pub pressure: Option<f64>,
    pub temperature: Option<f64>,
    pub humidity: Option<f64>,
}

pub enum RustCommand {
    SetProject { xml: String },
    Start,
    Stop,
    TogglePaused,
    InjectMessage { msg_type: String, values: Vec<(String, DartValue)> },
}

#[derive(Clone, Copy, PartialOrd, Ord, PartialEq, Eq, Debug)]
pub struct DartRequestKey {
    pub value: usize,
}
impl DartRequestKey {
    fn new(key: AsyncKey<Result<SimpleValue, CompactString>>) -> Self {
        let res = Self { value: KEY_COUNTER.fetch_add(1, MemOrder::Relaxed) };
        PENDING_REQUESTS.lock().unwrap().insert(res, key);
        res
    }
}

#[derive(Clone, Copy, PartialOrd, Ord, PartialEq, Eq, Debug)]
pub struct DartCommandKey {
    pub value: usize,
}
impl DartCommandKey {
    fn new(key: AsyncKey<Result<(), CompactString>>) -> Self {
        let res = Self { value: KEY_COUNTER.fetch_add(1, MemOrder::Relaxed) };
        PENDING_COMMANDS.lock().unwrap().insert(res, key);
        res
    }
}

#[derive(Clone, Debug)]
pub enum DartCommand {
    UpdatePaused { value: bool },

    Stdout { msg: String },
    Stderr { msg: String },

    PlaySound { key: Option<DartCommandKey>, content: Vec<u8> },

    ClearControls { key: DartRequestKey },
    RemoveControl { key: DartRequestKey, id: String },

    AddLabel { key: DartRequestKey, info: LabelInfo },
    AddButton { key: DartRequestKey, info: ButtonInfo },
    AddTextField { key: DartRequestKey, info: TextFieldInfo },
    AddJoystick { key: DartRequestKey, info: JoystickInfo },
    AddTouchpad { key: DartRequestKey, info: TouchpadInfo },
    AddSlider { key: DartRequestKey, info: SliderInfo },
    AddToggle { key: DartRequestKey, info: ToggleInfo },
    AddRadioButton { key: DartRequestKey, info: RadioButtonInfo },
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
    GetLightLevel { key: DartRequestKey },
    GetTemperature { key: DartRequestKey },
    GetFacingDirection { key: DartRequestKey },
    GetOrientation { key: DartRequestKey },
    GetCompassHeading { key: DartRequestKey },
    GetCompassDirection { key: DartRequestKey },
    GetCompassCardinalDirection { key: DartRequestKey },
    GetLocationLatLong { key: DartRequestKey },
    GetLocationHeading { key: DartRequestKey },
    GetLocationAltitude { key: DartRequestKey },
    GetMicrophoneLevel { key: DartRequestKey },
    GetProximity { key: DartRequestKey },
    GetStepCount { key: DartRequestKey },

    ListenToSensors { key: DartRequestKey, sensors: SensorUpdateInfo },
}

pub enum DartValue {
    Bool(bool),
    Number(f64),
    String(String),
    Image(Vec<u8>, Option<(f64, f64)>),
    Audio(Vec<u8>),
    List(Vec<DartValue>),
}
impl DartValue {
    fn into_simple(self) -> SimpleValue {
        fn parse_num(num: f64) -> Number {
            Number::new(num).unwrap_or_else(|_| Number::new(0.0).unwrap())
        }
        match self {
            DartValue::Bool(x) => SimpleValue::Bool(x),
            DartValue::Number(x) => SimpleValue::Number(parse_num(x)),
            DartValue::String(x) => SimpleValue::String(x.into()),
            DartValue::Image(content, center) => SimpleValue::Image(Image { content, center: center.map(|(x, y)| (parse_num(x), parse_num(y))) }),
            DartValue::Audio(content) => SimpleValue::Audio(Audio { content }),
            DartValue::List(x) => SimpleValue::List(x.into_iter().map(DartValue::into_simple).collect()),
        }
    }
}

pub enum RequestResult {
    Ok(DartValue),
    Err(String),
}
impl RequestResult {
    fn into_result(self) -> Result<DartValue, String> {
        match self {
            Self::Ok(x) => Ok(x),
            Self::Err(x) => Err(x),
        }
    }
}

pub enum CommandResult {
    Ok,
    Err(String),
}
impl CommandResult {
    fn into_result(self) -> Result<(), String> {
        match self {
            Self::Ok => Ok(()),
            Self::Err(x) => Err(x),
        }
    }
}

pub fn initialize(device_id: String, utc_offset_in_seconds: i32) {
    if INITIALIZED.swap(true, MemOrder::Relaxed) { return }
    thread::spawn(move || {
        let config = Config::<C, StdSystem<C>> {
            command: Some(Rc::new(move |_, key, command, _| {
                match &command {
                    Command::Print { style: _, value } => {
                        if let Some(value) = value {
                            DART_COMMANDS.lock().unwrap().send(DartCommand::Stdout { msg: value.to_string() });
                        }
                        key.complete(Ok(()));
                    }
                    Command::PlaySound { sound, blocking } => {
                        let key = match blocking {
                            true => Some(DartCommandKey::new(key)),
                            false => {
                                key.complete(Ok(()));
                                None
                            }
                        };
                        DART_COMMANDS.lock().unwrap().send(DartCommand::PlaySound { content: sound.content.clone(), key });
                    }
                    _ => return CommandStatus::UseDefault { key, command },
                }
                CommandStatus::Handled
            })),
            request: Some(Rc::new(move |_, key, request, _| {
                let is_local_id = |s: &Value<C, StdSystem<C>>| -> bool {
                    match s.as_string() {
                        Ok(x) => x.chars().all(|x| x == '0') || *x == device_id,
                        Err(_) => false,
                    }
                };
                fn parse_options<'gc, C: CustomTypes<S>, S: System<C>>(name: &str, opts: &Value<'gc, C, S>, allowed: &[&str]) -> Result<BTreeMap<CompactString, Value<'gc, C, S>>, CompactString> {
                    let mut res = BTreeMap::new();
                    match opts {
                        Value::String(x) if x.is_empty() => (),
                        Value::List(x) => for x in x.borrow().iter() {
                            match x {
                                Value::List(x) => {
                                    let x = x.borrow();
                                    if x.len() != 2 {
                                        return Err(format_compact!("'{name}' must be a list of pairs (length 2 lists)"));
                                    }
                                    let k = match x[0].as_string() {
                                        Ok(x) => x.into_owned(),
                                        Err(_) => return Err(format_compact!("'{name}' keys must be strings")),
                                    };
                                    if !allowed.iter().any(|x| **x == *k) {
                                        return Err(format_compact!("'{name}': unknown option '{k}'"));
                                    }
                                    if res.insert(k.clone(), x[1].clone()).is_some() {
                                        return Err(format_compact!("'{name}': option '{k}' was already specified"));
                                    }
                                }
                                _ => return Err(format_compact!("'{name}' must be a list of lists")),
                            }
                        }
                        _ => return Err(format_compact!("{name}' must be a list of lists")),
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
                                key.complete(Err(format_compact!("'{}': expected bool, got {:?}", stringify!($n), x.get_type())));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => f64) => {
                        match $e.as_number() {
                            Ok(x) => x.get(),
                            Err(x) => {
                                key.complete(Err(format_compact!("'{}': expected number, got {:?}", stringify!($n), x.got)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => String) => {
                        match $e.as_string() {
                            Ok(x) => (*x).to_owned(),
                            Err(x) => {
                                key.complete(Err(format_compact!("'{}': expected string, got {:?}", stringify!($n), x.got)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => ControlId) => {{
                        let res = parse!($n := $e => String);
                        if res.len() > 255 {
                            key.complete(Err(format_compact!("'{}': string too long (max 255 bytes)", stringify!($n))));
                            return RequestStatus::Handled;
                        }
                        res
                    }};
                    ($n:ident := $e:expr => ButtonStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "rectangle" => ButtonStyleInfo::Rectangle,
                            "ellipse" => ButtonStyleInfo::Ellipse,
                            "square" => ButtonStyleInfo::Square,
                            "circle" => ButtonStyleInfo::Circle,
                            x => {
                                key.complete(Err(format_compact!("'{}': unknown button style '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => TouchpadStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "rectangle" => TouchpadStyleInfo::Rectangle,
                            "square" => TouchpadStyleInfo::Square,
                            x => {
                                key.complete(Err(format_compact!("'{}': unknown touchpad style '{}'", stringify!($n), x)));
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
                                key.complete(Err(format_compact!("'{}': unknown text align '{}'", stringify!($n), x)));
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
                                key.complete(Err(format_compact!("'{}': unknown image fit mode '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => SliderStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "slider" => SliderStyleInfo::Slider,
                            "progress" => SliderStyleInfo::Progress,
                            x => {
                                key.complete(Err(format_compact!("'{}': unknown slider style '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => ToggleStyleInfo) => {
                        match parse!($n := $e => String).as_str() {
                            "switch" => ToggleStyleInfo::Switch,
                            "checkbox" => ToggleStyleInfo::Checkbox,
                            x => {
                                key.complete(Err(format_compact!("'{}': unknown toggle style '{}'", stringify!($n), x)));
                                return RequestStatus::Handled;
                            }
                        }
                    };
                    ($n:ident := $e:expr => Image) => {
                        match &$e {
                            Value::Image(x) => (**x).clone(),
                            x => {
                                key.complete(Err(format_compact!("{}': expected image, got {:?}", stringify!($n), x.get_type())));
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
                    ($n:ident := $e:expr => {$($f:ident),*$(,)?}) => {
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
                    Request::Rpc { service, rpc, args } if *service == "PhoneIoT" => {
                        macro_rules! simple_request {
                            ($cmd:ident) => {{
                                if args.len() != 1 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }
                                DART_COMMANDS.lock().unwrap().send(DartCommand::$cmd { key: DartRequestKey::new(key) });
                                RequestStatus::Handled
                            }};
                        }
                        match rpc.as_str() {
                            "getSensors" => {
                                if !args.is_empty() {
                                    return RequestStatus::UseDefault { key, request };
                                }
                                key.complete(Ok(SimpleValue::from_json(json!([
                                    "gravity", "gyroscope", "orientation", "accelerometer", "magneticField", "linearAcceleration", "lightLevel",
                                    "microphoneLevel", "proximity", "stepCount", "location", "pressure", "temperature", "humidity",
                                ])).unwrap()));
                                RequestStatus::Handled
                            }
                            "getColor" => {
                                if args.len() != 4 {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let r = parse!(red := args.as_slice()[0].value => f64) as u8;
                                let g = parse!(green := args.as_slice()[1].value => f64) as u8;
                                let b = parse!(blue := args.as_slice()[2].value => f64) as u8;
                                let a = parse!(alpha := args.as_slice()[3].value => f64) as u8;

                                let encoded = ((a as i32) << 24) | ((r as i32) << 16) | ((g as i32) << 8) | b as i32;
                                key.complete(Ok(SimpleValue::Number(Number::new(encoded as f64).unwrap())));
                                RequestStatus::Handled
                            }
                            "setCredentials" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }
                                key.complete(Ok(SimpleValue::String(CompactString::new("OK"))));
                                RequestStatus::Handled
                            }
                            "authenticate" | "listenToGUI" => {
                                if args.len() != 1 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }
                                key.complete(Ok(SimpleValue::String(CompactString::new("OK"))));
                                RequestStatus::Handled
                            }
                            "clearControls" => {
                                if args.len() != 1 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                CONTROL_COUNTER.store(0, MemOrder::Relaxed);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::ClearControls { key: DartRequestKey::new(key) });
                                RequestStatus::Handled
                            }
                            "removeControl" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::RemoveControl { key: DartRequestKey::new(key), id });
                                RequestStatus::Handled
                            }
                            "addButton" => {
                                if args.len() != 7 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let width = parse!(width := args.as_slice()[3].value => f64);
                                let height = parse!(height := args.as_slice()[4].value => f64);
                                let text = parse!(text := args.as_slice()[5].value => String);
                                let options = parse!(options := args.as_slice()[6].value => { id, event, style, color, textColor, landscape, fontSize });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                                let back_color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                                let fore_color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(WHITE);
                                let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                                let event = parse!(event := options.get("event") => Option<String>);
                                let style = parse!(style := options.get("style") => Option<ButtonStyleInfo>).unwrap_or(ButtonStyleInfo::Rectangle);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddButton { key: DartRequestKey::new(key), info: ButtonInfo {
                                    id, x, y, width, height, text, landscape, back_color, fore_color, font_size, event, style,
                                }});
                                RequestStatus::Handled
                            }
                            "addLabel" => {
                                if args.len() != 5 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let text = parse!(text := args.as_slice()[3].value => String);
                                let options = parse!(options := args.as_slice()[4].value => { id, textColor, align, fontSize, landscape });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(BLACK);
                                let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                                let align = parse!(align := options.get("align") => Option<TextAlignInfo>).unwrap_or(TextAlignInfo::Left);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddLabel { key: DartRequestKey::new(key), info: LabelInfo {
                                    x, y, text, id, color, font_size, landscape, align,
                                }});
                                RequestStatus::Handled
                            }
                            "addTextField" => {
                                if args.len() != 6 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let width = parse!(width := args.as_slice()[3].value => f64);
                                let height = parse!(height := args.as_slice()[4].value => f64);
                                let options = parse!(options := args.as_slice()[5].value => { id, event, text, color, textColor, readonly, fontSize, align, landscape });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let back_color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                                let fore_color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(BLACK);
                                let text = parse!(text := options.get("text") => Option<String>).unwrap_or_default();
                                let event = parse!(event := options.get("event") => Option<String>);
                                let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(false);
                                let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                                let align = parse!(align := options.get("align") => Option<TextAlignInfo>).unwrap_or(TextAlignInfo::Left);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddTextField { key: DartRequestKey::new(key), info: TextFieldInfo {
                                    id, x, y, width, height, back_color, fore_color, text, event, font_size, landscape, readonly, align,
                                }});
                                RequestStatus::Handled
                            }
                            "addJoystick" => {
                                if args.len() != 5 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let width = parse!(width := args.as_slice()[3].value => f64);
                                let options = parse!(options := args.as_slice()[4].value => { id, event, color, landscape });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let event = parse!(event := options.get("event") => Option<String>);
                                let color = parse!(event := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddJoystick { key: DartRequestKey::new(key), info: JoystickInfo {
                                    x, y, width, id, event, color, landscape,
                                }});
                                RequestStatus::Handled
                            }
                            "addTouchpad" => {
                                if args.len() != 6 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let width = parse!(width := args.as_slice()[3].value => f64);
                                let height = parse!(height := args.as_slice()[4].value => f64);
                                let options = parse!(options := args.as_slice()[5].value => { id, event, color, style, landscape });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let event = parse!(event := options.get("event") => Option<String>);
                                let color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                                let style = parse!(style := options.get("style") => Option<TouchpadStyleInfo>).unwrap_or(TouchpadStyleInfo::Rectangle);
                                let landscape = parse!(style := options.get("landscape") => Option<bool>).unwrap_or(false);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddTouchpad { key: DartRequestKey::new(key), info: TouchpadInfo {
                                    x, y, width, height, id, event, color, style, landscape,
                                }});
                                RequestStatus::Handled
                            }
                            "addSlider" => {
                                if args.len() != 5 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let width = parse!(width := args.as_slice()[3].value => f64);
                                let options = parse!(options := args.as_slice()[4].value => { id, event, color, value, style, landscape, readonly });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let event = parse!(event := options.get("event") => Option<String>);
                                let color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                                let value = parse!(value := options.get("value") => Option<f64>).unwrap_or(0.0);
                                let style = parse!(style := options.get("style") => Option<SliderStyleInfo>).unwrap_or(SliderStyleInfo::Slider);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                                let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(false);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddSlider { key: DartRequestKey::new(key), info: SliderInfo {
                                    x, y, width, id, event, color, value, style, landscape, readonly,
                                }});
                                RequestStatus::Handled
                            }
                            "addToggle" => {
                                if args.len() != 5 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let text = parse!(text := args.as_slice()[3].value => String);
                                let options = parse!(options := args.as_slice()[4].value => { style, id, event, checked, color, textColor, fontSize, landscape, readonly });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let style = parse!(style := options.get("style") => Option<ToggleStyleInfo>).unwrap_or(ToggleStyleInfo::Switch);
                                let event = parse!(event := options.get("event") => Option<String>);
                                let checked = parse!(checked := options.get("checked") => Option<bool>).unwrap_or(false);
                                let back_color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                                let fore_color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(BLACK);
                                let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                                let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(false);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddToggle { key: DartRequestKey::new(key), info: ToggleInfo {
                                    x, y, text, id, style, event, checked, fore_color, back_color, font_size, landscape, readonly,
                                }});
                                RequestStatus::Handled
                            }
                            "addRadioButton" => {
                                if args.len() != 5 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let text = parse!(text := args.as_slice()[3].value => String);
                                let options = parse!(options := args.as_slice()[4].value => { group, id, event, checked, color, textColor, fontSize, landscape, readonly });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let group = parse!(id := options.get("group") => Option<ControlId>).unwrap_or_default();
                                let event = parse!(event := options.get("event") => Option<String>);
                                let checked = parse!(checked := options.get("checked") => Option<bool>).unwrap_or(false);
                                let back_color = parse!(color := options.get("color") => Option<ColorInfo>).unwrap_or(BLUE);
                                let fore_color = parse!(textColor := options.get("textColor") => Option<ColorInfo>).unwrap_or(BLACK);
                                let font_size = parse!(fontSize := options.get("fontSize") => Option<f64>).unwrap_or(1.0);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                                let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(false);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddRadioButton { key: DartRequestKey::new(key), info: RadioButtonInfo {
                                    x, y, text, id, group, event, checked, fore_color, back_color, font_size, landscape, readonly,
                                }});
                                RequestStatus::Handled
                            }
                            "addImageDisplay" => {
                                if args.len() != 6 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let x = parse!(x := args.as_slice()[1].value => f64);
                                let y = parse!(y := args.as_slice()[2].value => f64);
                                let width = parse!(width := args.as_slice()[3].value => f64);
                                let height = parse!(height := args.as_slice()[4].value => f64);
                                let options = parse!(options := args.as_slice()[5].value => { id, event, readonly, landscape, fit });
                                let id = parse!(id := options.get("id") => Option<ControlId>).unwrap_or_else(new_control_id);
                                let event = parse!(event := options.get("event") => Option<String>);
                                let readonly = parse!(readonly := options.get("readonly") => Option<bool>).unwrap_or(true);
                                let landscape = parse!(landscape := options.get("landscape") => Option<bool>).unwrap_or(false);
                                let fit = parse!(fit := options.get("fit") => Option<ImageFitInfo>).unwrap_or(ImageFitInfo::Fit);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::AddImageDisplay { key: DartRequestKey::new(key), info: ImageDisplayInfo {
                                    id, x, y, width, height, event, readonly, landscape, fit,
                                }});
                                RequestStatus::Handled
                            }
                            "listenToSensors" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let sensors = parse!(sensors := args.as_slice()[1].value => {
                                    gravity, gyroscope, orientation, accelerometer, magneticField, linearAcceleration,
                                    lightLevel, microphoneLevel, proximity, stepCount, location, pressure, temperature, humidity,
                                });
                                let gravity = parse!(gravity := sensors.get("gravity") => Option<f64>);
                                let gyroscope = parse!(gyroscope := sensors.get("gyroscope") => Option<f64>);
                                let orientation = parse!(orientation := sensors.get("orientation") => Option<f64>);
                                let accelerometer = parse!(accelerometer := sensors.get("accelerometer") => Option<f64>);
                                let magnetic_field = parse!(magneticField := sensors.get("magneticField") => Option<f64>);
                                let linear_acceleration = parse!(linearAcceleration := sensors.get("linearAcceleration") => Option<f64>);
                                let light_level = parse!(lightLevel := sensors.get("lightLevel") => Option<f64>);
                                let microphone_level = parse!(microphoneLevel := sensors.get("microphoneLevel") => Option<f64>);
                                let proximity = parse!(proximity := sensors.get("proximity") => Option<f64>);
                                let step_count = parse!(stepCount := sensors.get("stepCount") => Option<f64>);
                                let location = parse!(location := sensors.get("location") => Option<f64>);
                                let pressure = parse!(pressure := sensors.get("pressure") => Option<f64>);
                                let temperature = parse!(temperature := sensors.get("temperature") => Option<f64>);
                                let humidity = parse!(humidity := sensors.get("humidity") => Option<f64>);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::ListenToSensors { key: DartRequestKey::new(key), sensors: SensorUpdateInfo {
                                    gravity, gyroscope, orientation, accelerometer, magnetic_field, linear_acceleration,
                                    light_level, microphone_level, proximity, step_count, location, pressure, temperature, humidity,
                                }});
                                RequestStatus::Handled
                            }
                            "stopSensors" => {
                                if args.len() != 1 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                DART_COMMANDS.lock().unwrap().send(DartCommand::ListenToSensors { key: DartRequestKey::new(key), sensors: SensorUpdateInfo::default() });
                                RequestStatus::Handled
                            }
                            "getText" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::GetText { key: DartRequestKey::new(key), id });
                                RequestStatus::Handled
                            }
                            "setText" => {
                                if args.len() != 3 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);
                                let value = parse!(text := args.as_slice()[2].value => String);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::SetText { key: DartRequestKey::new(key), id, value });
                                RequestStatus::Handled
                            }
                            "isPressed" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::IsPressed { key: DartRequestKey::new(key), id });
                                RequestStatus::Handled
                            }
                            "getPosition" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::GetPosition { key: DartRequestKey::new(key), id });
                                RequestStatus::Handled
                            }
                            "getImage" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::GetImage { key: DartRequestKey::new(key), id });
                                RequestStatus::Handled
                            }
                            "setImage" => {
                                if args.len() != 3 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);
                                let img = parse!(img := args.as_slice()[2].value => Image);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::SetImage { key: DartRequestKey::new(key), id, value: img.content });
                                RequestStatus::Handled
                            }
                            "getLevel" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::GetLevel { key: DartRequestKey::new(key), id });
                                RequestStatus::Handled
                            }
                            "setLevel" => {
                                if args.len() != 3 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);
                                let value = parse!(value := args.as_slice()[2].value => f64);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::SetLevel { key: DartRequestKey::new(key), id, value });
                                RequestStatus::Handled
                            }
                            "getToggleState" => {
                                if args.len() != 2 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::GetToggleState { key: DartRequestKey::new(key), id });
                                RequestStatus::Handled
                            }
                            "setToggleState" => {
                                if args.len() != 3 || !is_local_id(&args.as_slice()[0].value) {
                                    return RequestStatus::UseDefault { key, request };
                                }

                                let id = parse!(id := args.as_slice()[1].value => ControlId);
                                let value = parse!(state := args.as_slice()[2].value => bool);

                                DART_COMMANDS.lock().unwrap().send(DartCommand::SetToggleState { key: DartRequestKey::new(key), id, value });
                                RequestStatus::Handled
                            }
                            "getAccelerometer" => simple_request!(GetAccelerometer),
                            "getLinearAcceleration" => simple_request!(GetLinearAccelerometer),
                            "getGyroscope" => simple_request!(GetGyroscope),
                            "getMagneticField" => simple_request!(GetMagnetometer),
                            "getGravity" => simple_request!(GetGravity),
                            "getPressure" => simple_request!(GetPressure),
                            "getRelativeHumidity" => simple_request!(GetRelativeHumidity),
                            "getLightLevel" => simple_request!(GetLightLevel),
                            "getTemperature" => simple_request!(GetTemperature),
                            "getFacingDirection" => simple_request!(GetFacingDirection),
                            "getOrientation" => simple_request!(GetOrientation),
                            "getCompassHeading" => simple_request!(GetCompassHeading),
                            "getCompassDirection" => simple_request!(GetCompassDirection),
                            "getCompassCardinalDirection" => simple_request!(GetCompassCardinalDirection),
                            "getLocation" => simple_request!(GetLocationLatLong),
                            "getGPSHeading" => simple_request!(GetLocationHeading),
                            "getAltitude" => simple_request!(GetLocationAltitude),
                            "getMicrophoneLevel" => simple_request!(GetMicrophoneLevel),
                            "getProximity" => simple_request!(GetProximity),
                            "getStepCount" => simple_request!(GetStepCount),
                            _ => RequestStatus::UseDefault { key, request },
                        }
                    }
                    _ => RequestStatus::UseDefault { key, request },
                }
            })),
        };

        let utc_offset = UtcOffset::from_whole_seconds(utc_offset_in_seconds).unwrap_or(UtcOffset::UTC);
        let clock = Arc::new(Clock::new(utc_offset, Some(Precision::Medium)));
        let clock_clone = clock.clone();
        thread::spawn(move || loop {
            thread::sleep(CLOCK_INTERVAL);
            clock_clone.update();
        });

        let system = Rc::new(StdSystem::new_sync(CompactString::new(SERVER_URL), None, config, clock.clone()));
        let mut env = {
            let project = ast::Parser::default().parse(netsblox_vm::template::EMPTY_PROJECT).unwrap();
            get_env(&project.roles[0], system.clone()).unwrap()
        };
        let mut idle_sleeper = IdleAction::new(IDLE_SLEEP_THRESH, Box::new(move || thread::sleep(IDLE_SLEEP_TIME)));
        let mut pauser = PauseController::new(false);
        let mut next_collect = clock.read(Precision::Medium) + COLLECT_INTERVAL;

        loop {
            let commands = mem::take(&mut *RUST_COMMANDS.lock().unwrap());
            for cmd in commands {
                match cmd {
                    RustCommand::SetProject { xml } => match ast::Parser::default().parse(&xml) {
                        Ok(project) => match project.roles.as_slice() {
                            [role] => match get_env(role, system.clone()) {
                                Ok(x) => {
                                    env = x;
                                    DART_COMMANDS.lock().unwrap().send(DartCommand::Stdout { msg: "loaded project".into() });
                                }
                                Err(e) => DART_COMMANDS.lock().unwrap().send(DartCommand::Stderr { msg: format!("project load error: {e:?}") }),
                            }
                            x => DART_COMMANDS.lock().unwrap().send(DartCommand::Stderr { msg: format!("project load error: expected 1 role, got {}", x.len()) } ),
                        }
                        Err(e) => DART_COMMANDS.lock().unwrap().send(DartCommand::Stderr { msg: format!("project load error: {e:?}") }),
                    }
                    RustCommand::Start => env.mutate(|mc, env| {
                        pauser.set_paused(false);
                        env.proj.borrow_mut(mc).input(mc, Input::Start);
                    }),
                    RustCommand::Stop => env.mutate(|mc, env| {
                        env.proj.borrow_mut(mc).input(mc, Input::Stop);
                    }),
                    RustCommand::TogglePaused => {
                        pauser.toggle_paused();
                    }
                    RustCommand::InjectMessage { msg_type, values } => {
                        system.inject_message(msg_type.into(), values.into_iter().map(|x| (x.0.into(), x.1.into_simple())).collect());
                    }
                }
            }

            if pauser.is_paused() {
                thread::sleep(IDLE_SLEEP_TIME);
                continue;
            }

            env.mutate(|mc, env| {
                let mut proj = env.proj.borrow_mut(mc);
                for _ in 0..STEPS_PER_IO_ITER {
                    let res = proj.step(mc);
                    match &res {
                        ProjectStep::Error { error, proc } => {
                            DART_COMMANDS.lock().unwrap().send(DartCommand::Stderr { msg: format!("runtime error in entity {:?}: {:?}", proc.get_call_stack().last().unwrap().entity.borrow().name, error.cause) });
                        }
                        ProjectStep::Pause => {
                            pauser.set_paused(true);
                            break;
                        }
                        _ => (),
                    }
                    idle_sleeper.consume(&res);
                }
            });

            if clock.read(Precision::Low) > next_collect {
                env.collect_all();
                next_collect = clock.read(Precision::Medium) + COLLECT_INTERVAL;
            }
        }
    });
}

pub fn send_command(cmd: RustCommand) {
    RUST_COMMANDS.lock().unwrap().push(cmd);
}
pub fn recv_commands(sink: StreamSink<DartCommand>) {
    DART_COMMANDS.lock().unwrap().retry_backlog(sink);
}

pub fn complete_request(key: DartRequestKey, result: RequestResult) {
    let key = PENDING_REQUESTS.lock().unwrap().remove(&key);
    if let Some(key) = key {
        key.complete(result.into_result().map(DartValue::into_simple).map_err(Into::into));
    }
}
pub fn complete_command(key: DartCommandKey, result: CommandResult) {
    let key = PENDING_COMMANDS.lock().unwrap().remove(&key);
    if let Some(key) = key {
        key.complete(result.into_result().map_err(Into::into));
    }
}
