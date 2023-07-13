use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_initialize(port_: i64) {
    wire_initialize_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_send_command(port_: i64, cmd: *mut wire_RustCommand) {
    wire_send_command_impl(port_, cmd)
}

#[no_mangle]
pub extern "C" fn wire_recv_commands(port_: i64) {
    wire_recv_commands_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_complete_request(
    port_: i64,
    key: *mut wire_DartRequestKey,
    result: *mut wire_RequestResult,
) {
    wire_complete_request_impl(port_, key, result)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_dart_request_key_0() -> *mut wire_DartRequestKey {
    support::new_leak_box_ptr(wire_DartRequestKey::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_request_result_0() -> *mut wire_RequestResult {
    support::new_leak_box_ptr(wire_RequestResult::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_rust_command_0() -> *mut wire_RustCommand {
    support::new_leak_box_ptr(wire_RustCommand::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_simple_value_0() -> *mut wire_SimpleValue {
    support::new_leak_box_ptr(wire_SimpleValue::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_list___record__String_simple_value_0(
    len: i32,
) -> *mut wire_list___record__String_simple_value {
    let wrap = wire_list___record__String_simple_value {
        ptr: support::new_leak_vec_ptr(
            <wire___record__String_simple_value>::new_with_null_ptr(),
            len,
        ),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_list_simple_value_0(len: i32) -> *mut wire_list_simple_value {
    let wrap = wire_list_simple_value {
        ptr: support::new_leak_vec_ptr(<wire_SimpleValue>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}
impl Wire2Api<(String, SimpleValue)> for wire___record__String_simple_value {
    fn wire2api(self) -> (String, SimpleValue) {
        (self.field0.wire2api(), self.field1.wire2api())
    }
}

impl Wire2Api<DartRequestKey> for *mut wire_DartRequestKey {
    fn wire2api(self) -> DartRequestKey {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<DartRequestKey>::wire2api(*wrap).into()
    }
}
impl Wire2Api<RequestResult> for *mut wire_RequestResult {
    fn wire2api(self) -> RequestResult {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<RequestResult>::wire2api(*wrap).into()
    }
}
impl Wire2Api<RustCommand> for *mut wire_RustCommand {
    fn wire2api(self) -> RustCommand {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<RustCommand>::wire2api(*wrap).into()
    }
}
impl Wire2Api<SimpleValue> for *mut wire_SimpleValue {
    fn wire2api(self) -> SimpleValue {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<SimpleValue>::wire2api(*wrap).into()
    }
}
impl Wire2Api<DartRequestKey> for wire_DartRequestKey {
    fn wire2api(self) -> DartRequestKey {
        DartRequestKey {
            value: self.value.wire2api(),
        }
    }
}

impl Wire2Api<Vec<(String, SimpleValue)>> for *mut wire_list___record__String_simple_value {
    fn wire2api(self) -> Vec<(String, SimpleValue)> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}
impl Wire2Api<Vec<SimpleValue>> for *mut wire_list_simple_value {
    fn wire2api(self) -> Vec<SimpleValue> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}
impl Wire2Api<RequestResult> for wire_RequestResult {
    fn wire2api(self) -> RequestResult {
        match self.tag {
            0 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Ok);
                RequestResult::Ok(ans.field0.wire2api())
            },
            1 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Err);
                RequestResult::Err(ans.field0.wire2api())
            },
            _ => unreachable!(),
        }
    }
}
impl Wire2Api<RustCommand> for wire_RustCommand {
    fn wire2api(self) -> RustCommand {
        match self.tag {
            0 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.SetProject);
                RustCommand::SetProject {
                    xml: ans.xml.wire2api(),
                }
            },
            1 => RustCommand::Start,
            2 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.InjectMessage);
                RustCommand::InjectMessage {
                    msg_type: ans.msg_type.wire2api(),
                    values: ans.values.wire2api(),
                }
            },
            _ => unreachable!(),
        }
    }
}
impl Wire2Api<SimpleValue> for wire_SimpleValue {
    fn wire2api(self) -> SimpleValue {
        match self.tag {
            0 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Bool);
                SimpleValue::Bool(ans.field0.wire2api())
            },
            1 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Number);
                SimpleValue::Number(ans.field0.wire2api())
            },
            2 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.String);
                SimpleValue::String(ans.field0.wire2api())
            },
            3 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.List);
                SimpleValue::List(ans.field0.wire2api())
            },
            4 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Image);
                SimpleValue::Image(ans.field0.wire2api())
            },
            _ => unreachable!(),
        }
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}

// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire___record__String_simple_value {
    field0: *mut wire_uint_8_list,
    field1: wire_SimpleValue,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_DartRequestKey {
    value: usize,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list___record__String_simple_value {
    ptr: *mut wire___record__String_simple_value,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_simple_value {
    ptr: *mut wire_SimpleValue,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_RequestResult {
    tag: i32,
    kind: *mut RequestResultKind,
}

#[repr(C)]
pub union RequestResultKind {
    Ok: *mut wire_RequestResult_Ok,
    Err: *mut wire_RequestResult_Err,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_RequestResult_Ok {
    field0: *mut wire_SimpleValue,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_RequestResult_Err {
    field0: *mut wire_uint_8_list,
}
#[repr(C)]
#[derive(Clone)]
pub struct wire_RustCommand {
    tag: i32,
    kind: *mut RustCommandKind,
}

#[repr(C)]
pub union RustCommandKind {
    SetProject: *mut wire_RustCommand_SetProject,
    Start: *mut wire_RustCommand_Start,
    InjectMessage: *mut wire_RustCommand_InjectMessage,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_RustCommand_SetProject {
    xml: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_RustCommand_Start {}

#[repr(C)]
#[derive(Clone)]
pub struct wire_RustCommand_InjectMessage {
    msg_type: *mut wire_uint_8_list,
    values: *mut wire_list___record__String_simple_value,
}
#[repr(C)]
#[derive(Clone)]
pub struct wire_SimpleValue {
    tag: i32,
    kind: *mut SimpleValueKind,
}

#[repr(C)]
pub union SimpleValueKind {
    Bool: *mut wire_SimpleValue_Bool,
    Number: *mut wire_SimpleValue_Number,
    String: *mut wire_SimpleValue_String,
    List: *mut wire_SimpleValue_List,
    Image: *mut wire_SimpleValue_Image,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_SimpleValue_Bool {
    field0: bool,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_SimpleValue_Number {
    field0: f64,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_SimpleValue_String {
    field0: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_SimpleValue_List {
    field0: *mut wire_list_simple_value,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_SimpleValue_Image {
    field0: *mut wire_uint_8_list,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl NewWithNullPtr for wire___record__String_simple_value {
    fn new_with_null_ptr() -> Self {
        Self {
            field0: core::ptr::null_mut(),
            field1: Default::default(),
        }
    }
}

impl Default for wire___record__String_simple_value {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_DartRequestKey {
    fn new_with_null_ptr() -> Self {
        Self {
            value: Default::default(),
        }
    }
}

impl Default for wire_DartRequestKey {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl Default for wire_RequestResult {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_RequestResult {
    fn new_with_null_ptr() -> Self {
        Self {
            tag: -1,
            kind: core::ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn inflate_RequestResult_Ok() -> *mut RequestResultKind {
    support::new_leak_box_ptr(RequestResultKind {
        Ok: support::new_leak_box_ptr(wire_RequestResult_Ok {
            field0: core::ptr::null_mut(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_RequestResult_Err() -> *mut RequestResultKind {
    support::new_leak_box_ptr(RequestResultKind {
        Err: support::new_leak_box_ptr(wire_RequestResult_Err {
            field0: core::ptr::null_mut(),
        }),
    })
}

impl Default for wire_RustCommand {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_RustCommand {
    fn new_with_null_ptr() -> Self {
        Self {
            tag: -1,
            kind: core::ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn inflate_RustCommand_SetProject() -> *mut RustCommandKind {
    support::new_leak_box_ptr(RustCommandKind {
        SetProject: support::new_leak_box_ptr(wire_RustCommand_SetProject {
            xml: core::ptr::null_mut(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_RustCommand_InjectMessage() -> *mut RustCommandKind {
    support::new_leak_box_ptr(RustCommandKind {
        InjectMessage: support::new_leak_box_ptr(wire_RustCommand_InjectMessage {
            msg_type: core::ptr::null_mut(),
            values: core::ptr::null_mut(),
        }),
    })
}

impl Default for wire_SimpleValue {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_SimpleValue {
    fn new_with_null_ptr() -> Self {
        Self {
            tag: -1,
            kind: core::ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn inflate_SimpleValue_Bool() -> *mut SimpleValueKind {
    support::new_leak_box_ptr(SimpleValueKind {
        Bool: support::new_leak_box_ptr(wire_SimpleValue_Bool {
            field0: Default::default(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_SimpleValue_Number() -> *mut SimpleValueKind {
    support::new_leak_box_ptr(SimpleValueKind {
        Number: support::new_leak_box_ptr(wire_SimpleValue_Number {
            field0: Default::default(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_SimpleValue_String() -> *mut SimpleValueKind {
    support::new_leak_box_ptr(SimpleValueKind {
        String: support::new_leak_box_ptr(wire_SimpleValue_String {
            field0: core::ptr::null_mut(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_SimpleValue_List() -> *mut SimpleValueKind {
    support::new_leak_box_ptr(SimpleValueKind {
        List: support::new_leak_box_ptr(wire_SimpleValue_List {
            field0: core::ptr::null_mut(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_SimpleValue_Image() -> *mut SimpleValueKind {
    support::new_leak_box_ptr(SimpleValueKind {
        Image: support::new_leak_box_ptr(wire_SimpleValue_Image {
            field0: core::ptr::null_mut(),
        }),
    })
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
