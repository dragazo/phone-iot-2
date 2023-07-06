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
fn wire_get_status_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "get_status",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(get_status()),
    )
}
fn wire_set_project_impl(port_: MessagePort, xml: impl Wire2Api<String> + UnwindSafe) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "set_project",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_xml = xml.wire2api();
            move |task_callback| Ok(set_project(api_xml))
        },
    )
}
fn wire_start_project_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "start_project",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(start_project()),
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

impl Wire2Api<u8> for u8 {
    fn wire2api(self) -> u8 {
        self
    }
}

// Section: impl IntoDart

impl support::IntoDart for CustomButton {
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
impl support::IntoDartExceptPrimitive for CustomButton {}

impl support::IntoDart for CustomButtonStyle {
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
impl support::IntoDartExceptPrimitive for CustomButtonStyle {}
impl support::IntoDart for CustomColor {
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
impl support::IntoDartExceptPrimitive for CustomColor {}

impl support::IntoDart for CustomControl {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::Button(field0) => vec![0.into_dart(), field0.into_dart()],
            Self::Label(field0) => vec![1.into_dart(), field0.into_dart()],
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for CustomControl {}
impl support::IntoDart for CustomLabel {
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
impl support::IntoDartExceptPrimitive for CustomLabel {}

impl support::IntoDart for CustomTextAlign {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::Left => 0,
            Self::Center => 1,
            Self::Right => 2,
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for CustomTextAlign {}

impl support::IntoDart for MessageType {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::Output => 0,
            Self::Error => 1,
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for MessageType {}

impl support::IntoDart for Status {
    fn into_dart(self) -> support::DartAbi {
        vec![self.messages.into_dart(), self.controls.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for Status {}

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
