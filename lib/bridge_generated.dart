// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.82.3.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import "bridge_definitions.dart";
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';
import 'bridge_generated.io.dart'
    if (dart.library.html) 'bridge_generated.web.dart';

class NativeImpl implements Native {
  final NativePlatform _platform;
  factory NativeImpl(ExternalLibrary dylib) =>
      NativeImpl.raw(NativePlatform(dylib));

  /// Only valid on web/WASM platforms.
  factory NativeImpl.wasm(FutureOr<WasmModule> module) =>
      NativeImpl(module as ExternalLibrary);
  NativeImpl.raw(this._platform);
  Future<void> initialize(
      {required String deviceId,
      required int utcOffsetInSeconds,
      dynamic hint}) {
    var arg0 = _platform.api2wire_String(deviceId);
    var arg1 = api2wire_i32(utcOffsetInSeconds);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_initialize(port_, arg0, arg1),
      parseSuccessData: _wire2api_unit,
      parseErrorData: null,
      constMeta: kInitializeConstMeta,
      argValues: [deviceId, utcOffsetInSeconds],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kInitializeConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "initialize",
        argNames: ["deviceId", "utcOffsetInSeconds"],
      );

  Future<void> sendCommand({required RustCommand cmd, dynamic hint}) {
    var arg0 = _platform.api2wire_box_autoadd_rust_command(cmd);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_send_command(port_, arg0),
      parseSuccessData: _wire2api_unit,
      parseErrorData: null,
      constMeta: kSendCommandConstMeta,
      argValues: [cmd],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kSendCommandConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "send_command",
        argNames: ["cmd"],
      );

  Stream<DartCommand> recvCommands({dynamic hint}) {
    return _platform.executeStream(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_recv_commands(port_),
      parseSuccessData: _wire2api_dart_command,
      parseErrorData: null,
      constMeta: kRecvCommandsConstMeta,
      argValues: [],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kRecvCommandsConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "recv_commands",
        argNames: [],
      );

  Future<void> completeRequest(
      {required DartRequestKey key,
      required RequestResult result,
      dynamic hint}) {
    var arg0 = _platform.api2wire_box_autoadd_dart_request_key(key);
    var arg1 = _platform.api2wire_box_autoadd_request_result(result);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) =>
          _platform.inner.wire_complete_request(port_, arg0, arg1),
      parseSuccessData: _wire2api_unit,
      parseErrorData: null,
      constMeta: kCompleteRequestConstMeta,
      argValues: [key, result],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kCompleteRequestConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "complete_request",
        argNames: ["key", "result"],
      );

  void dispose() {
    _platform.dispose();
  }
// Section: wire2api

  String _wire2api_String(dynamic raw) {
    return raw as String;
  }

  bool _wire2api_bool(dynamic raw) {
    return raw as bool;
  }

  ButtonInfo _wire2api_box_autoadd_button_info(dynamic raw) {
    return _wire2api_button_info(raw);
  }

  DartRequestKey _wire2api_box_autoadd_dart_request_key(dynamic raw) {
    return _wire2api_dart_request_key(raw);
  }

  double _wire2api_box_autoadd_f64(dynamic raw) {
    return raw as double;
  }

  ImageDisplayInfo _wire2api_box_autoadd_image_display_info(dynamic raw) {
    return _wire2api_image_display_info(raw);
  }

  JoystickInfo _wire2api_box_autoadd_joystick_info(dynamic raw) {
    return _wire2api_joystick_info(raw);
  }

  LabelInfo _wire2api_box_autoadd_label_info(dynamic raw) {
    return _wire2api_label_info(raw);
  }

  RadioButtonInfo _wire2api_box_autoadd_radio_button_info(dynamic raw) {
    return _wire2api_radio_button_info(raw);
  }

  SensorUpdateInfo _wire2api_box_autoadd_sensor_update_info(dynamic raw) {
    return _wire2api_sensor_update_info(raw);
  }

  SliderInfo _wire2api_box_autoadd_slider_info(dynamic raw) {
    return _wire2api_slider_info(raw);
  }

  TextFieldInfo _wire2api_box_autoadd_text_field_info(dynamic raw) {
    return _wire2api_text_field_info(raw);
  }

  ToggleInfo _wire2api_box_autoadd_toggle_info(dynamic raw) {
    return _wire2api_toggle_info(raw);
  }

  TouchpadInfo _wire2api_box_autoadd_touchpad_info(dynamic raw) {
    return _wire2api_touchpad_info(raw);
  }

  ButtonInfo _wire2api_button_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 12)
      throw Exception('unexpected arr length: expect 12 but see ${arr.length}');
    return ButtonInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      width: _wire2api_f64(arr[3]),
      height: _wire2api_f64(arr[4]),
      backColor: _wire2api_color_info(arr[5]),
      foreColor: _wire2api_color_info(arr[6]),
      text: _wire2api_String(arr[7]),
      event: _wire2api_opt_String(arr[8]),
      fontSize: _wire2api_f64(arr[9]),
      style: _wire2api_button_style_info(arr[10]),
      landscape: _wire2api_bool(arr[11]),
    );
  }

  ButtonStyleInfo _wire2api_button_style_info(dynamic raw) {
    return ButtonStyleInfo.values[raw as int];
  }

  ColorInfo _wire2api_color_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 4)
      throw Exception('unexpected arr length: expect 4 but see ${arr.length}');
    return ColorInfo(
      a: _wire2api_u8(arr[0]),
      r: _wire2api_u8(arr[1]),
      g: _wire2api_u8(arr[2]),
      b: _wire2api_u8(arr[3]),
    );
  }

  DartCommand _wire2api_dart_command(dynamic raw) {
    switch (raw[0]) {
      case 0:
        return DartCommand_UpdatePaused(
          value: _wire2api_bool(raw[1]),
        );
      case 1:
        return DartCommand_Stdout(
          msg: _wire2api_String(raw[1]),
        );
      case 2:
        return DartCommand_Stderr(
          msg: _wire2api_String(raw[1]),
        );
      case 3:
        return DartCommand_ClearControls(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 4:
        return DartCommand_RemoveControl(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
        );
      case 5:
        return DartCommand_AddLabel(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_label_info(raw[2]),
        );
      case 6:
        return DartCommand_AddButton(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_button_info(raw[2]),
        );
      case 7:
        return DartCommand_AddTextField(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_text_field_info(raw[2]),
        );
      case 8:
        return DartCommand_AddJoystick(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_joystick_info(raw[2]),
        );
      case 9:
        return DartCommand_AddTouchpad(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_touchpad_info(raw[2]),
        );
      case 10:
        return DartCommand_AddSlider(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_slider_info(raw[2]),
        );
      case 11:
        return DartCommand_AddToggle(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_toggle_info(raw[2]),
        );
      case 12:
        return DartCommand_AddRadioButton(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_radio_button_info(raw[2]),
        );
      case 13:
        return DartCommand_AddImageDisplay(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          info: _wire2api_box_autoadd_image_display_info(raw[2]),
        );
      case 14:
        return DartCommand_GetText(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
        );
      case 15:
        return DartCommand_SetText(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
          value: _wire2api_String(raw[3]),
        );
      case 16:
        return DartCommand_GetLevel(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
        );
      case 17:
        return DartCommand_SetLevel(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
          value: _wire2api_f64(raw[3]),
        );
      case 18:
        return DartCommand_GetToggleState(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
        );
      case 19:
        return DartCommand_SetToggleState(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
          value: _wire2api_bool(raw[3]),
        );
      case 20:
        return DartCommand_GetImage(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
        );
      case 21:
        return DartCommand_SetImage(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
          value: _wire2api_uint_8_list(raw[3]),
        );
      case 22:
        return DartCommand_GetPosition(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
        );
      case 23:
        return DartCommand_IsPressed(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          id: _wire2api_String(raw[2]),
        );
      case 24:
        return DartCommand_GetAccelerometer(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 25:
        return DartCommand_GetLinearAccelerometer(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 26:
        return DartCommand_GetGyroscope(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 27:
        return DartCommand_GetMagnetometer(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 28:
        return DartCommand_GetGravity(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 29:
        return DartCommand_GetPressure(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 30:
        return DartCommand_GetRelativeHumidity(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 31:
        return DartCommand_GetLightLevel(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 32:
        return DartCommand_GetTemperature(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 33:
        return DartCommand_GetFacingDirection(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 34:
        return DartCommand_GetOrientation(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 35:
        return DartCommand_GetCompassHeading(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 36:
        return DartCommand_GetCompassDirection(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 37:
        return DartCommand_GetCompassCardinalDirection(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 38:
        return DartCommand_GetLocationLatLong(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 39:
        return DartCommand_GetLocationHeading(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 40:
        return DartCommand_GetLocationAltitude(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 41:
        return DartCommand_GetMicrophoneLevel(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 42:
        return DartCommand_GetProximity(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 43:
        return DartCommand_GetStepCount(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
        );
      case 44:
        return DartCommand_ListenToSensors(
          key: _wire2api_box_autoadd_dart_request_key(raw[1]),
          sensors: _wire2api_box_autoadd_sensor_update_info(raw[2]),
        );
      default:
        throw Exception("unreachable");
    }
  }

  DartRequestKey _wire2api_dart_request_key(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return DartRequestKey(
      value: _wire2api_usize(arr[0]),
    );
  }

  double _wire2api_f64(dynamic raw) {
    return raw as double;
  }

  int _wire2api_i32(dynamic raw) {
    return raw as int;
  }

  ImageDisplayInfo _wire2api_image_display_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 9)
      throw Exception('unexpected arr length: expect 9 but see ${arr.length}');
    return ImageDisplayInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      width: _wire2api_f64(arr[3]),
      height: _wire2api_f64(arr[4]),
      event: _wire2api_opt_String(arr[5]),
      readonly: _wire2api_bool(arr[6]),
      landscape: _wire2api_bool(arr[7]),
      fit: _wire2api_image_fit_info(arr[8]),
    );
  }

  ImageFitInfo _wire2api_image_fit_info(dynamic raw) {
    return ImageFitInfo.values[raw as int];
  }

  JoystickInfo _wire2api_joystick_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 7)
      throw Exception('unexpected arr length: expect 7 but see ${arr.length}');
    return JoystickInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      width: _wire2api_f64(arr[3]),
      event: _wire2api_opt_String(arr[4]),
      color: _wire2api_color_info(arr[5]),
      landscape: _wire2api_bool(arr[6]),
    );
  }

  LabelInfo _wire2api_label_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 8)
      throw Exception('unexpected arr length: expect 8 but see ${arr.length}');
    return LabelInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      color: _wire2api_color_info(arr[3]),
      text: _wire2api_String(arr[4]),
      fontSize: _wire2api_f64(arr[5]),
      align: _wire2api_text_align_info(arr[6]),
      landscape: _wire2api_bool(arr[7]),
    );
  }

  String? _wire2api_opt_String(dynamic raw) {
    return raw == null ? null : _wire2api_String(raw);
  }

  double? _wire2api_opt_box_autoadd_f64(dynamic raw) {
    return raw == null ? null : _wire2api_box_autoadd_f64(raw);
  }

  RadioButtonInfo _wire2api_radio_button_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 12)
      throw Exception('unexpected arr length: expect 12 but see ${arr.length}');
    return RadioButtonInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      text: _wire2api_String(arr[3]),
      group: _wire2api_String(arr[4]),
      event: _wire2api_opt_String(arr[5]),
      checked: _wire2api_bool(arr[6]),
      foreColor: _wire2api_color_info(arr[7]),
      backColor: _wire2api_color_info(arr[8]),
      fontSize: _wire2api_f64(arr[9]),
      landscape: _wire2api_bool(arr[10]),
      readonly: _wire2api_bool(arr[11]),
    );
  }

  SensorUpdateInfo _wire2api_sensor_update_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 14)
      throw Exception('unexpected arr length: expect 14 but see ${arr.length}');
    return SensorUpdateInfo(
      gravity: _wire2api_opt_box_autoadd_f64(arr[0]),
      gyroscope: _wire2api_opt_box_autoadd_f64(arr[1]),
      orientation: _wire2api_opt_box_autoadd_f64(arr[2]),
      accelerometer: _wire2api_opt_box_autoadd_f64(arr[3]),
      magneticField: _wire2api_opt_box_autoadd_f64(arr[4]),
      linearAcceleration: _wire2api_opt_box_autoadd_f64(arr[5]),
      lightLevel: _wire2api_opt_box_autoadd_f64(arr[6]),
      microphoneLevel: _wire2api_opt_box_autoadd_f64(arr[7]),
      proximity: _wire2api_opt_box_autoadd_f64(arr[8]),
      stepCount: _wire2api_opt_box_autoadd_f64(arr[9]),
      location: _wire2api_opt_box_autoadd_f64(arr[10]),
      pressure: _wire2api_opt_box_autoadd_f64(arr[11]),
      temperature: _wire2api_opt_box_autoadd_f64(arr[12]),
      humidity: _wire2api_opt_box_autoadd_f64(arr[13]),
    );
  }

  SliderInfo _wire2api_slider_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 10)
      throw Exception('unexpected arr length: expect 10 but see ${arr.length}');
    return SliderInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      width: _wire2api_f64(arr[3]),
      event: _wire2api_opt_String(arr[4]),
      color: _wire2api_color_info(arr[5]),
      value: _wire2api_f64(arr[6]),
      style: _wire2api_slider_style_info(arr[7]),
      landscape: _wire2api_bool(arr[8]),
      readonly: _wire2api_bool(arr[9]),
    );
  }

  SliderStyleInfo _wire2api_slider_style_info(dynamic raw) {
    return SliderStyleInfo.values[raw as int];
  }

  TextAlignInfo _wire2api_text_align_info(dynamic raw) {
    return TextAlignInfo.values[raw as int];
  }

  TextFieldInfo _wire2api_text_field_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 13)
      throw Exception('unexpected arr length: expect 13 but see ${arr.length}');
    return TextFieldInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      width: _wire2api_f64(arr[3]),
      height: _wire2api_f64(arr[4]),
      backColor: _wire2api_color_info(arr[5]),
      foreColor: _wire2api_color_info(arr[6]),
      text: _wire2api_String(arr[7]),
      event: _wire2api_opt_String(arr[8]),
      fontSize: _wire2api_f64(arr[9]),
      landscape: _wire2api_bool(arr[10]),
      readonly: _wire2api_bool(arr[11]),
      align: _wire2api_text_align_info(arr[12]),
    );
  }

  ToggleInfo _wire2api_toggle_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 12)
      throw Exception('unexpected arr length: expect 12 but see ${arr.length}');
    return ToggleInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      text: _wire2api_String(arr[3]),
      style: _wire2api_toggle_style_info(arr[4]),
      event: _wire2api_opt_String(arr[5]),
      checked: _wire2api_bool(arr[6]),
      foreColor: _wire2api_color_info(arr[7]),
      backColor: _wire2api_color_info(arr[8]),
      fontSize: _wire2api_f64(arr[9]),
      landscape: _wire2api_bool(arr[10]),
      readonly: _wire2api_bool(arr[11]),
    );
  }

  ToggleStyleInfo _wire2api_toggle_style_info(dynamic raw) {
    return ToggleStyleInfo.values[raw as int];
  }

  TouchpadInfo _wire2api_touchpad_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 9)
      throw Exception('unexpected arr length: expect 9 but see ${arr.length}');
    return TouchpadInfo(
      id: _wire2api_String(arr[0]),
      x: _wire2api_f64(arr[1]),
      y: _wire2api_f64(arr[2]),
      width: _wire2api_f64(arr[3]),
      height: _wire2api_f64(arr[4]),
      event: _wire2api_opt_String(arr[5]),
      color: _wire2api_color_info(arr[6]),
      style: _wire2api_touchpad_style_info(arr[7]),
      landscape: _wire2api_bool(arr[8]),
    );
  }

  TouchpadStyleInfo _wire2api_touchpad_style_info(dynamic raw) {
    return TouchpadStyleInfo.values[raw as int];
  }

  int _wire2api_u8(dynamic raw) {
    return raw as int;
  }

  Uint8List _wire2api_uint_8_list(dynamic raw) {
    return raw as Uint8List;
  }

  void _wire2api_unit(dynamic raw) {
    return;
  }

  int _wire2api_usize(dynamic raw) {
    return castInt(raw);
  }
}

// Section: api2wire

@protected
bool api2wire_bool(bool raw) {
  return raw;
}

@protected
double api2wire_f64(double raw) {
  return raw;
}

@protected
int api2wire_i32(int raw) {
  return raw;
}

@protected
int api2wire_u8(int raw) {
  return raw;
}

@protected
int api2wire_usize(int raw) {
  return raw;
}
// Section: finalizer
