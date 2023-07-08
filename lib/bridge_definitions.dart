// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.78.0.
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
  Future<void> initialize({dynamic hint});

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
  const factory DartCommand.clearControls() = DartCommand_ClearControls;
  const factory DartCommand.addButton({
    required ButtonInfo info,
    required DartRequestKey key,
  }) = DartCommand_AddButton;
  const factory DartCommand.addLabel({
    required LabelInfo info,
    required DartRequestKey key,
  }) = DartCommand_AddLabel;
}

class DartRequestKey {
  final int value;

  const DartRequestKey({
    required this.value,
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
}

@freezed
sealed class SimpleValue with _$SimpleValue {
  const factory SimpleValue.number(
    double field0,
  ) = SimpleValue_Number;
  const factory SimpleValue.string(
    String field0,
  ) = SimpleValue_String;
  const factory SimpleValue.list(
    List<SimpleValue> field0,
  ) = SimpleValue_List;
}

enum TextAlignInfo {
  Left,
  Center,
  Right,
}
