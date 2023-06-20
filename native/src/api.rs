// This is the entry point of your Rust library.
// When adding new code to your project, note that only items used
// here will be transformed to their Dart equivalents.

use std::sync::{Mutex, mpsc};

use netsblox_vm;

struct VirtualMachine {
    current_project: String,
    command_sender: mpsc::Sender<Command>,
}
pub struct Status {

}
enum Command { // bridge doesn't support enum variants with fields, so not pub
    SetProject { xml: String },
}

lazy_static! {
    static ref VM: Mutex<VirtualMachine> = {
        let (command_sender, command_receiver) = mpsc::channel();
        Mutex::new(VirtualMachine {
            current_project: netsblox_vm::template::EMPTY_PROJECT.to_owned(),
            command_sender,
        })
    };
}

pub fn get_status() -> Status {
    let vm = VM.lock().unwrap();
    Status {

    }
}

pub fn set_project(xml: String) {
    let vm = VM.lock().unwrap();
    vm.command_sender.send(Command::SetProject { xml }).unwrap();
}
