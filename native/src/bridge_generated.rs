#![allow(
    non_camel_case_types,
    unused,
    clippy::redundant_closure,
    clippy::useless_conversion,
    clippy::unit_arg,
    clippy::double_parens,
    non_snake_case,
    clippy::too_many_arguments
)]
// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.78.0.

use crate::api::*;
use core::panic::UnwindSafe;
use flutter_rust_bridge::*;
use std::ffi::c_void;
use std::sync::Arc;

// Section: imports

// Section: wire functions

fn wire_initialize_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "initialize",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(initialize()),
    )
}
fn wire_send_command_impl(port_: MessagePort, cmd: impl Wire2Api<RustCommand> + UnwindSafe) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "send_command",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_cmd = cmd.wire2api();
            move |task_callback| Ok(send_command(api_cmd))
        },
    )
}
fn wire_recv_commands_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "recv_commands",
            port: Some(port_),
            mode: FfiCallMode::Stream,
        },
        move || move |task_callback| Ok(recv_commands(task_callback.stream_sink())),
    )
}
fn wire_complete_request_impl(
    port_: MessagePort,
    key: impl Wire2Api<DartRequestKey> + UnwindSafe,
    result: impl Wire2Api<RequestResult> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "complete_request",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_key = key.wire2api();
            let api_result = result.wire2api();
            move |task_callback| Ok(complete_request(api_key, api_result))
        },
    )
}
// Section: wrapper structs

// Section: static checks

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

pub trait Wire2Api<T> {
    fn wire2api(self) -> T;
}

impl<T, S> Wire2Api<Option<T>> for *mut S
where
    *mut S: Wire2Api<T>,
{
    fn wire2api(self) -> Option<T> {
        (!self.is_null()).then(|| self.wire2api())
    }
}

impl Wire2Api<f64> for f64 {
    fn wire2api(self) -> f64 {
        self
    }
}

impl Wire2Api<u8> for u8 {
    fn wire2api(self) -> u8 {
        self
    }
}

impl Wire2Api<usize> for usize {
    fn wire2api(self) -> usize {
        self
    }
}
// Section: impl IntoDart

impl support::IntoDart for ButtonInfo {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.id.into_dart(),
            self.x.into_dart(),
            self.y.into_dart(),
            self.width.into_dart(),
            self.height.into_dart(),
            self.back_color.into_dart(),
            self.fore_color.into_dart(),
            self.text.into_dart(),
            self.event.into_dart(),
            self.font_size.into_dart(),
            self.style.into_dart(),
            self.landscape.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for ButtonInfo {}

impl support::IntoDart for ButtonStyleInfo {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::Rectangle => 0,
            Self::Ellipse => 1,
            Self::Square => 2,
            Self::Circle => 3,
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for ButtonStyleInfo {}
impl support::IntoDart for ColorInfo {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.a.into_dart(),
            self.r.into_dart(),
            self.g.into_dart(),
            self.b.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for ColorInfo {}

impl support::IntoDart for DartCommand {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::Stdout { msg } => vec![0.into_dart(), msg.into_dart()],
            Self::Stderr { msg } => vec![1.into_dart(), msg.into_dart()],
            Self::ClearControls { key } => vec![2.into_dart(), key.into_dart()],
            Self::RemoveControl { key, id } => vec![3.into_dart(), key.into_dart(), id.into_dart()],
            Self::AddLabel { key, info } => vec![4.into_dart(), key.into_dart(), info.into_dart()],
            Self::AddButton { key, info } => vec![5.into_dart(), key.into_dart(), info.into_dart()],
            Self::AddTextField { key, info } => {
                vec![6.into_dart(), key.into_dart(), info.into_dart()]
            }
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for DartCommand {}
impl support::IntoDart for DartRequestKey {
    fn into_dart(self) -> support::DartAbi {
        vec![self.value.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for DartRequestKey {}

impl support::IntoDart for LabelInfo {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.id.into_dart(),
            self.x.into_dart(),
            self.y.into_dart(),
            self.color.into_dart(),
            self.text.into_dart(),
            self.font_size.into_dart(),
            self.align.into_dart(),
            self.landscape.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for LabelInfo {}

impl support::IntoDart for TextAlignInfo {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::Left => 0,
            Self::Center => 1,
            Self::Right => 2,
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for TextAlignInfo {}
impl support::IntoDart for TextFieldInfo {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.id.into_dart(),
            self.x.into_dart(),
            self.y.into_dart(),
            self.width.into_dart(),
            self.height.into_dart(),
            self.back_color.into_dart(),
            self.fore_color.into_dart(),
            self.text.into_dart(),
            self.event.into_dart(),
            self.font_size.into_dart(),
            self.landscape.into_dart(),
            self.readonly.into_dart(),
            self.align.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for TextFieldInfo {}

// Section: executor

support::lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: support::DefaultHandler = Default::default();
}

/// cbindgen:ignore
#[cfg(target_family = "wasm")]
#[path = "bridge_generated.web.rs"]
mod web;
#[cfg(target_family = "wasm")]
pub use web::*;

#[cfg(not(target_family = "wasm"))]
#[path = "bridge_generated.io.rs"]
mod io;
#[cfg(not(target_family = "wasm"))]
pub use io::*;
