use super::*;
// Section: wire functions

#[wasm_bindgen]
pub fn wire_initialize(port_: MessagePort, utc_offset_in_seconds: i32) {
    wire_initialize_impl(port_, utc_offset_in_seconds)
}

#[wasm_bindgen]
pub fn wire_send_command(port_: MessagePort, cmd: JsValue) {
    wire_send_command_impl(port_, cmd)
}

#[wasm_bindgen]
pub fn wire_recv_commands(port_: MessagePort) {
    wire_recv_commands_impl(port_)
}

#[wasm_bindgen]
pub fn wire_complete_request(port_: MessagePort, key: JsValue, result: JsValue) {
    wire_complete_request_impl(port_, key, result)
}

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for String {
    fn wire2api(self) -> String {
        self
    }
}
impl Wire2Api<(String, SimpleValue)> for JsValue {
    fn wire2api(self) -> (String, SimpleValue) {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            2,
            "Expected 2 elements, got {}",
            self_.length()
        );
        (self_.get(0).wire2api(), self_.get(1).wire2api())
    }
}

impl Wire2Api<DartRequestKey> for JsValue {
    fn wire2api(self) -> DartRequestKey {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            1,
            "Expected 1 elements, got {}",
            self_.length()
        );
        DartRequestKey {
            value: self_.get(0).wire2api(),
        }
    }
}

impl Wire2Api<Vec<(String, SimpleValue)>> for JsValue {
    fn wire2api(self) -> Vec<(String, SimpleValue)> {
        self.dyn_into::<JsArray>()
            .unwrap()
            .iter()
            .map(Wire2Api::wire2api)
            .collect()
    }
}
impl Wire2Api<Vec<SimpleValue>> for JsValue {
    fn wire2api(self) -> Vec<SimpleValue> {
        self.dyn_into::<JsArray>()
            .unwrap()
            .iter()
            .map(Wire2Api::wire2api)
            .collect()
    }
}
impl Wire2Api<RequestResult> for JsValue {
    fn wire2api(self) -> RequestResult {
        let self_ = self.unchecked_into::<JsArray>();
        match self_.get(0).unchecked_into_f64() as _ {
            0 => RequestResult::Ok(self_.get(1).wire2api()),
            1 => RequestResult::Err(self_.get(1).wire2api()),
            _ => unreachable!(),
        }
    }
}
impl Wire2Api<RustCommand> for JsValue {
    fn wire2api(self) -> RustCommand {
        let self_ = self.unchecked_into::<JsArray>();
        match self_.get(0).unchecked_into_f64() as _ {
            0 => RustCommand::SetProject {
                xml: self_.get(1).wire2api(),
            },
            1 => RustCommand::Start,
            2 => RustCommand::Stop,
            3 => RustCommand::InjectMessage {
                msg_type: self_.get(1).wire2api(),
                values: self_.get(2).wire2api(),
            },
            _ => unreachable!(),
        }
    }
}
impl Wire2Api<SimpleValue> for JsValue {
    fn wire2api(self) -> SimpleValue {
        let self_ = self.unchecked_into::<JsArray>();
        match self_.get(0).unchecked_into_f64() as _ {
            0 => SimpleValue::Bool(self_.get(1).wire2api()),
            1 => SimpleValue::Number(self_.get(1).wire2api()),
            2 => SimpleValue::String(self_.get(1).wire2api()),
            3 => SimpleValue::List(self_.get(1).wire2api()),
            4 => SimpleValue::Image(self_.get(1).wire2api()),
            _ => unreachable!(),
        }
    }
}

impl Wire2Api<Vec<u8>> for Box<[u8]> {
    fn wire2api(self) -> Vec<u8> {
        self.into_vec()
    }
}

// Section: impl Wire2Api for JsValue

impl Wire2Api<String> for JsValue {
    fn wire2api(self) -> String {
        self.as_string().expect("non-UTF-8 string, or not a string")
    }
}
impl Wire2Api<bool> for JsValue {
    fn wire2api(self) -> bool {
        self.is_truthy()
    }
}
impl Wire2Api<f64> for JsValue {
    fn wire2api(self) -> f64 {
        self.unchecked_into_f64() as _
    }
}
impl Wire2Api<i32> for JsValue {
    fn wire2api(self) -> i32 {
        self.unchecked_into_f64() as _
    }
}
impl Wire2Api<u8> for JsValue {
    fn wire2api(self) -> u8 {
        self.unchecked_into_f64() as _
    }
}
impl Wire2Api<Vec<u8>> for JsValue {
    fn wire2api(self) -> Vec<u8> {
        self.unchecked_into::<js_sys::Uint8Array>().to_vec().into()
    }
}
impl Wire2Api<usize> for JsValue {
    fn wire2api(self) -> usize {
        self.unchecked_into_f64() as _
    }
}
