use super::*;
// Section: wire functions

#[wasm_bindgen]
pub fn wire_initialize(port_: MessagePort) {
    wire_initialize_impl(port_)
}

#[wasm_bindgen]
pub fn wire_get_status(port_: MessagePort) {
    wire_get_status_impl(port_)
}

#[wasm_bindgen]
pub fn wire_set_project(port_: MessagePort, xml: String) {
    wire_set_project_impl(port_, xml)
}

#[wasm_bindgen]
pub fn wire_start_project(port_: MessagePort) {
    wire_start_project_impl(port_)
}

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for String {
    fn wire2api(self) -> String {
        self
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
