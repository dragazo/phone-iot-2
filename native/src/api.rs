use std::sync::atomic::{AtomicBool, Ordering as MemOrder};
use std::collections::VecDeque;
use std::time::Duration;
use std::{mem, thread};
use std::sync::Mutex;
use std::rc::Rc;

use netsblox_vm::project::{Project, IdleAction, ProjectStep};
use netsblox_vm::std_system::StdSystem;
use netsblox_vm::bytecode::{ByteCode, Locations};
use netsblox_vm::runtime::{CustomTypes, GetType, EntityKind, IntermediateType, ErrorCause, Value, FromAstError, Config};
use netsblox_vm::gc::{Gc, RefLock, Collect, Arena, Rootable, Mutation};
use netsblox_vm::json::Json;
use netsblox_vm::ast;

const SERVER_URL: &'static str = "https://editor.netsblox.org";
const IDLE_SLEEP_THRESH: usize = 256;
const IDLE_SLEEP_TIME: Duration = Duration::from_millis(1);

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

enum Command {
    SetProject { xml: String },
}

static COMMANDS: Mutex<VecDeque<Command>> = Mutex::new(VecDeque::new());
static ERRORS: Mutex<Vec<String>> = Mutex::new(Vec::new());
static INITIALIZED: AtomicBool = AtomicBool::new(false);

// -----------------------------------------------------------------

pub fn initialize() {
    if INITIALIZED.swap(true, MemOrder::Relaxed) { return }
    thread::spawn(move || {
        let config = Config::<C, StdSystem<C>>::default();
        let system = Rc::new(StdSystem::new(SERVER_URL.to_owned(), None, config));
        let mut env = {
            let project = ast::Parser::default().parse(netsblox_vm::template::EMPTY_PROJECT).unwrap();
            get_env(&project.roles[0], system.clone()).unwrap()
        };
        let mut idle_sleeper = IdleAction::new(IDLE_SLEEP_THRESH, Box::new(move || thread::sleep(IDLE_SLEEP_TIME)));

        loop {
            let cmd = COMMANDS.lock().unwrap().pop_front();
            match cmd {
                Some(Command::SetProject { xml }) => match ast::Parser::default().parse(&xml) {
                    Ok(project) => match project.roles.as_slice() {
                        [role] => match get_env(role, system.clone()) {
                            Ok(x) => env = x,
                            Err(e) => ERRORS.lock().unwrap().push(format!("project load error: {e:?}")),
                        }
                        x => ERRORS.lock().unwrap().push(format!("project load error: expected 1 role, got {}", x.len())),
                    }
                    Err(e) => ERRORS.lock().unwrap().push(format!("project load error: {e:?}")),
                }
                None => (),
            }

            env.mutate(|mc, env| {
                let res = env.proj.borrow_mut(mc).step(mc);
                if let ProjectStep::Error { error, proc } = &res {
                    ERRORS.lock().unwrap().push(format!("runtime error in entity {:?}: {:?}", proc.get_call_stack().last().unwrap().entity.borrow().name, error.cause));
                }
                idle_sleeper.consume(&res);
            });
        }
    });
}

pub struct Status {
    pub errors: Vec<String>,
}

pub fn get_status() -> Status {
    Status {
        errors: mem::take(&mut *ERRORS.lock().unwrap()),
    }
}
pub fn set_project(xml: String) {
    COMMANDS.lock().unwrap().push_back(Command::SetProject { xml });
}
