// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.79.0.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import 'bridge_generated.io.dart'
    if (dart.library.html) 'bridge_generated.web.dart';
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;

part 'bridge_definitions.freezed.dart';

abstract class Native {
  Future<void> initialize({required int utcOffsetInSeconds, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kInitializeConstMeta;

  Future<void> sendCommand({required RustCommand cmd, dynamic hint});

  FlutterRustBridgeTaskConstMeta get kSendCommandConstMeta;

  Stream<DartCommand> recvCommands({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kRecvCommandsConstMeta;

  Future<void> completeRequest(
      {required DartRequestKey key,
      required RequestResult result,
      dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCompleteRequestConstMeta;
}

class ButtonInfo {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final ColorInfo backColor;
  final ColorInfo foreColor;
  final String text;
  final String? event;
  final double fontSize;
  final ButtonStyleInfo style;
  final bool landscape;

  const ButtonInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.backColor,
    required this.foreColor,
    required this.text,
    this.event,
    required this.fontSize,
    required this.style,
    required this.landscape,
  });
}

enum ButtonStyleInfo {
  Rectangle,
  Ellipse,
  Square,
  Circle,
}

class ColorInfo {
  final int a;
  final int r;
  final int g;
  final int b;

  const ColorInfo({
    required this.a,
    required this.r,
    required this.g,
    required this.b,
  });
}

@freezed
sealed class DartCommand with _$DartCommand {
  const factory DartCommand.stdout({
    required String msg,
  }) = DartCommand_Stdout;
  const factory DartCommand.stderr({
    required String msg,
  }) = DartCommand_Stderr;
  const factory DartCommand.clearControls({
    required DartRequestKey key,
  }) = DartCommand_ClearControls;
  const factory DartCommand.removeControl({
    required DartRequestKey key,
    required String id,
  }) = DartCommand_RemoveControl;
  const factory DartCommand.addLabel({
    required DartRequestKey key,
    required LabelInfo info,
  }) = DartCommand_AddLabel;
  const factory DartCommand.addButton({
    required DartRequestKey key,
    required ButtonInfo info,
  }) = DartCommand_AddButton;
  const factory DartCommand.addTextField({
    required DartRequestKey key,
    required TextFieldInfo info,
  }) = DartCommand_AddTextField;
  const factory DartCommand.addJoystick({
    required DartRequestKey key,
    required JoystickInfo info,
  }) = DartCommand_AddJoystick;
  const factory DartCommand.addTouchpad({
    required DartRequestKey key,
    required TouchpadInfo info,
  }) = DartCommand_AddTouchpad;
  const factory DartCommand.addSlider({
    required DartRequestKey key,
    required SliderInfo info,
  }) = DartCommand_AddSlider;
  const factory DartCommand.addToggle({
    required DartRequestKey key,
    required ToggleInfo info,
  }) = DartCommand_AddToggle;
  const factory DartCommand.addImageDisplay({
    required DartRequestKey key,
    required ImageDisplayInfo info,
  }) = DartCommand_AddImageDisplay;
  const factory DartCommand.getText({
    required DartRequestKey key,
    required String id,
  }) = DartCommand_GetText;
  const factory DartCommand.setText({
    required DartRequestKey key,
    required String id,
    required String value,
  }) = DartCommand_SetText;
  const factory DartCommand.getLevel({
    required DartRequestKey key,
    required String id,
  }) = DartCommand_GetLevel;
  const factory DartCommand.setLevel({
    required DartRequestKey key,
    required String id,
    required double value,
  }) = DartCommand_SetLevel;
  const factory DartCommand.getToggleState({
    required DartRequestKey key,
    required String id,
  }) = DartCommand_GetToggleState;
  const factory DartCommand.setToggleState({
    required DartRequestKey key,
    required String id,
    required bool value,
  }) = DartCommand_SetToggleState;
  const factory DartCommand.getImage({
    required DartRequestKey key,
    required String id,
  }) = DartCommand_GetImage;
  const factory DartCommand.setImage({
    required DartRequestKey key,
    required String id,
    required Uint8List value,
  }) = DartCommand_SetImage;
  const factory DartCommand.getPosition({
    required DartRequestKey key,
    required String id,
  }) = DartCommand_GetPosition;
  const factory DartCommand.isPressed({
    required DartRequestKey key,
    required String id,
  }) = DartCommand_IsPressed;
  const factory DartCommand.getAccelerometer({
    required DartRequestKey key,
  }) = DartCommand_GetAccelerometer;
  const factory DartCommand.getLinearAccelerometer({
    required DartRequestKey key,
  }) = DartCommand_GetLinearAccelerometer;
  const factory DartCommand.getGyroscope({
    required DartRequestKey key,
  }) = DartCommand_GetGyroscope;
  const factory DartCommand.getMagnetometer({
    required DartRequestKey key,
  }) = DartCommand_GetMagnetometer;
  const factory DartCommand.getGravity({
    required DartRequestKey key,
  }) = DartCommand_GetGravity;
  const factory DartCommand.getPressure({
    required DartRequestKey key,
  }) = DartCommand_GetPressure;
}

class DartRequestKey {
  final int value;

  const DartRequestKey({
    required this.value,
  });
}

class ImageDisplayInfo {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? event;
  final bool readonly;
  final bool landscape;
  final ImageFitInfo fit;

  const ImageDisplayInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.event,
    required this.readonly,
    required this.landscape,
    required this.fit,
  });
}

enum ImageFitInfo {
  Fit,
  Zoom,
  Stretch,
}

class JoystickInfo {
  final String id;
  final double x;
  final double y;
  final double width;
  final String? event;
  final ColorInfo color;
  final bool landscape;

  const JoystickInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    this.event,
    required this.color,
    required this.landscape,
  });
}

class LabelInfo {
  final String id;
  final double x;
  final double y;
  final ColorInfo color;
  final String text;
  final double fontSize;
  final TextAlignInfo align;
  final bool landscape;

  const LabelInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
    required this.text,
    required this.fontSize,
    required this.align,
    required this.landscape,
  });
}

@freezed
sealed class RequestResult with _$RequestResult {
  const factory RequestResult.ok(
    SimpleValue field0,
  ) = RequestResult_Ok;
  const factory RequestResult.err(
    String field0,
  ) = RequestResult_Err;
}

@freezed
sealed class RustCommand with _$RustCommand {
  const factory RustCommand.setProject({
    required String xml,
  }) = RustCommand_SetProject;
  const factory RustCommand.start() = RustCommand_Start;
  const factory RustCommand.stop() = RustCommand_Stop;
  const factory RustCommand.injectMessage({
    required String msgType,
    required List<(String, SimpleValue)> values,
  }) = RustCommand_InjectMessage;
}

@freezed
sealed class SimpleValue with _$SimpleValue {
  const factory SimpleValue.bool(
    bool field0,
  ) = SimpleValue_Bool;
  const factory SimpleValue.number(
    double field0,
  ) = SimpleValue_Number;
  const factory SimpleValue.string(
    String field0,
  ) = SimpleValue_String;
  const factory SimpleValue.list(
    List<SimpleValue> field0,
  ) = SimpleValue_List;
  const factory SimpleValue.image(
    Uint8List field0,
  ) = SimpleValue_Image;
}

class SliderInfo {
  final String id;
  final double x;
  final double y;
  final double width;
  final String? event;
  final ColorInfo color;
  final double value;
  final SliderStyleInfo style;
  final bool landscape;
  final bool readonly;

  const SliderInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    this.event,
    required this.color,
    required this.value,
    required this.style,
    required this.landscape,
    required this.readonly,
  });
}

enum SliderStyleInfo {
  Slider,
  Progress,
}

enum TextAlignInfo {
  Left,
  Center,
  Right,
}

class TextFieldInfo {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final ColorInfo backColor;
  final ColorInfo foreColor;
  final String text;
  final String? event;
  final double fontSize;
  final bool landscape;
  final bool readonly;
  final TextAlignInfo align;

  const TextFieldInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.backColor,
    required this.foreColor,
    required this.text,
    this.event,
    required this.fontSize,
    required this.landscape,
    required this.readonly,
    required this.align,
  });
}

class ToggleInfo {
  final String id;
  final double x;
  final double y;
  final String text;
  final ToggleStyleInfo style;
  final String? event;
  final bool checked;
  final ColorInfo foreColor;
  final ColorInfo backColor;
  final double fontSize;
  final bool landscape;
  final bool readonly;

  const ToggleInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    required this.style,
    this.event,
    required this.checked,
    required this.foreColor,
    required this.backColor,
    required this.fontSize,
    required this.landscape,
    required this.readonly,
  });
}

enum ToggleStyleInfo {
  Switch,
  Checkbox,
}

class TouchpadInfo {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? event;
  final ColorInfo color;
  final TouchpadStyleInfo style;
  final bool landscape;

  const TouchpadInfo({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.event,
    required this.color,
    required this.style,
    required this.landscape,
  });
}

enum TouchpadStyleInfo {
  Rectangle,
  Square,
}
