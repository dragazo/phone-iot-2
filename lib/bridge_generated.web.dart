// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.82.6.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import "bridge_definitions.dart";
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';
import 'bridge_generated.dart';
export 'bridge_generated.dart';

class NativePlatform extends FlutterRustBridgeBase<NativeWire>
    with FlutterRustBridgeSetupMixin {
  NativePlatform(FutureOr<WasmModule> dylib) : super(NativeWire(dylib)) {
    setupMixinConstructor();
  }
  Future<void> setup() => inner.init;

// Section: api2wire

  @protected
  String api2wire_String(String raw) {
    return raw;
  }

  @protected
  List<dynamic> api2wire___record__String_dart_value((String, DartValue) raw) {
    return [api2wire_String(raw.$1), api2wire_dart_value(raw.$2)];
  }

  @protected
  List<dynamic> api2wire___record__f64_f64((double, double) raw) {
    return [api2wire_f64(raw.$1), api2wire_f64(raw.$2)];
  }

  @protected
  List<dynamic> api2wire_box_autoadd___record__f64_f64((double, double) raw) {
    return api2wire___record__f64_f64(raw);
  }

  @protected
  List<dynamic> api2wire_box_autoadd_command_result(CommandResult raw) {
    return api2wire_command_result(raw);
  }

  @protected
  List<dynamic> api2wire_box_autoadd_dart_command_key(DartCommandKey raw) {
    return api2wire_dart_command_key(raw);
  }

  @protected
  List<dynamic> api2wire_box_autoadd_dart_request_key(DartRequestKey raw) {
    return api2wire_dart_request_key(raw);
  }

  @protected
  List<dynamic> api2wire_box_autoadd_dart_value(DartValue raw) {
    return api2wire_dart_value(raw);
  }

  @protected
  List<dynamic> api2wire_box_autoadd_request_result(RequestResult raw) {
    return api2wire_request_result(raw);
  }

  @protected
  List<dynamic> api2wire_box_autoadd_rust_command(RustCommand raw) {
    return api2wire_rust_command(raw);
  }

  @protected
  List<dynamic> api2wire_command_result(CommandResult raw) {
    if (raw is CommandResult_Ok) {
      return [0];
    }
    if (raw is CommandResult_Err) {
      return [1, api2wire_String(raw.field0)];
    }

    throw Exception('unreachable');
  }

  @protected
  List<dynamic> api2wire_dart_command_key(DartCommandKey raw) {
    return [api2wire_usize(raw.value)];
  }

  @protected
  List<dynamic> api2wire_dart_request_key(DartRequestKey raw) {
    return [api2wire_usize(raw.value)];
  }

  @protected
  List<dynamic> api2wire_dart_value(DartValue raw) {
    if (raw is DartValue_Bool) {
      return [0, api2wire_bool(raw.field0)];
    }
    if (raw is DartValue_Number) {
      return [1, api2wire_f64(raw.field0)];
    }
    if (raw is DartValue_String) {
      return [2, api2wire_String(raw.field0)];
    }
    if (raw is DartValue_Image) {
      return [
        3,
        api2wire_uint_8_list(raw.field0),
        api2wire_opt_box_autoadd___record__f64_f64(raw.field1)
      ];
    }
    if (raw is DartValue_Audio) {
      return [4, api2wire_uint_8_list(raw.field0)];
    }
    if (raw is DartValue_List) {
      return [5, api2wire_list_dart_value(raw.field0)];
    }

    throw Exception('unreachable');
  }

  @protected
  List<dynamic> api2wire_list___record__String_dart_value(
      List<(String, DartValue)> raw) {
    return raw.map(api2wire___record__String_dart_value).toList();
  }

  @protected
  List<dynamic> api2wire_list_dart_value(List<DartValue> raw) {
    return raw.map(api2wire_dart_value).toList();
  }

  @protected
  List<dynamic>? api2wire_opt_box_autoadd___record__f64_f64(
      (double, double)? raw) {
    return raw == null ? null : api2wire_box_autoadd___record__f64_f64(raw);
  }

  @protected
  List<dynamic> api2wire_request_result(RequestResult raw) {
    if (raw is RequestResult_Ok) {
      return [0, api2wire_box_autoadd_dart_value(raw.field0)];
    }
    if (raw is RequestResult_Err) {
      return [1, api2wire_String(raw.field0)];
    }

    throw Exception('unreachable');
  }

  @protected
  List<dynamic> api2wire_rust_command(RustCommand raw) {
    if (raw is RustCommand_SetProject) {
      return [0, api2wire_String(raw.xml)];
    }
    if (raw is RustCommand_Start) {
      return [1];
    }
    if (raw is RustCommand_Stop) {
      return [2];
    }
    if (raw is RustCommand_TogglePaused) {
      return [3];
    }
    if (raw is RustCommand_InjectMessage) {
      return [
        4,
        api2wire_String(raw.msgType),
        api2wire_list___record__String_dart_value(raw.values)
      ];
    }

    throw Exception('unreachable');
  }

  @protected
  Uint8List api2wire_uint_8_list(Uint8List raw) {
    return raw;
  }

// Section: finalizer
}

// Section: WASM wire module

@JS('wasm_bindgen')
external NativeWasmModule get wasmModule;

@JS()
@anonymous
class NativeWasmModule implements WasmModule {
  external Object /* Promise */ call([String? moduleName]);
  external NativeWasmModule bind(dynamic thisArg, String moduleName);
  external dynamic /* void */ wire_initialize(
      NativePortType port_, String device_id, int utc_offset_in_seconds);

  external dynamic /* void */ wire_send_command(
      NativePortType port_, List<dynamic> cmd);

  external dynamic /* void */ wire_recv_commands(NativePortType port_);

  external dynamic /* void */ wire_complete_request(
      NativePortType port_, List<dynamic> key, List<dynamic> result);

  external dynamic /* void */ wire_complete_command(
      NativePortType port_, List<dynamic> key, List<dynamic> result);
}

// Section: WASM wire connector

class NativeWire extends FlutterRustBridgeWasmWireBase<NativeWasmModule> {
  NativeWire(FutureOr<WasmModule> module)
      : super(WasmModule.cast<NativeWasmModule>(module));

  void wire_initialize(
          NativePortType port_, String device_id, int utc_offset_in_seconds) =>
      wasmModule.wire_initialize(port_, device_id, utc_offset_in_seconds);

  void wire_send_command(NativePortType port_, List<dynamic> cmd) =>
      wasmModule.wire_send_command(port_, cmd);

  void wire_recv_commands(NativePortType port_) =>
      wasmModule.wire_recv_commands(port_);

  void wire_complete_request(
          NativePortType port_, List<dynamic> key, List<dynamic> result) =>
      wasmModule.wire_complete_request(port_, key, result);

  void wire_complete_command(
          NativePortType port_, List<dynamic> key, List<dynamic> result) =>
      wasmModule.wire_complete_command(port_, key, result);
}
