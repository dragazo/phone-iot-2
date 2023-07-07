// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bridge_definitions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$DartCommand {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String msg) stdout,
    required TResult Function(String msg) stderr,
    required TResult Function(ButtonInfo info, DartRequestKey key) addButton,
    required TResult Function(LabelInfo info, DartRequestKey key) addLabel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String msg)? stdout,
    TResult? Function(String msg)? stderr,
    TResult? Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult? Function(LabelInfo info, DartRequestKey key)? addLabel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String msg)? stdout,
    TResult Function(String msg)? stderr,
    TResult Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult Function(LabelInfo info, DartRequestKey key)? addLabel,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DartCommand_Stdout value) stdout,
    required TResult Function(DartCommand_Stderr value) stderr,
    required TResult Function(DartCommand_AddButton value) addButton,
    required TResult Function(DartCommand_AddLabel value) addLabel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DartCommand_Stdout value)? stdout,
    TResult? Function(DartCommand_Stderr value)? stderr,
    TResult? Function(DartCommand_AddButton value)? addButton,
    TResult? Function(DartCommand_AddLabel value)? addLabel,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DartCommand_Stdout value)? stdout,
    TResult Function(DartCommand_Stderr value)? stderr,
    TResult Function(DartCommand_AddButton value)? addButton,
    TResult Function(DartCommand_AddLabel value)? addLabel,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DartCommandCopyWith<$Res> {
  factory $DartCommandCopyWith(
          DartCommand value, $Res Function(DartCommand) then) =
      _$DartCommandCopyWithImpl<$Res, DartCommand>;
}

/// @nodoc
class _$DartCommandCopyWithImpl<$Res, $Val extends DartCommand>
    implements $DartCommandCopyWith<$Res> {
  _$DartCommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$DartCommand_StdoutCopyWith<$Res> {
  factory _$$DartCommand_StdoutCopyWith(_$DartCommand_Stdout value,
          $Res Function(_$DartCommand_Stdout) then) =
      __$$DartCommand_StdoutCopyWithImpl<$Res>;
  @useResult
  $Res call({String msg});
}

/// @nodoc
class __$$DartCommand_StdoutCopyWithImpl<$Res>
    extends _$DartCommandCopyWithImpl<$Res, _$DartCommand_Stdout>
    implements _$$DartCommand_StdoutCopyWith<$Res> {
  __$$DartCommand_StdoutCopyWithImpl(
      _$DartCommand_Stdout _value, $Res Function(_$DartCommand_Stdout) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msg = null,
  }) {
    return _then(_$DartCommand_Stdout(
      msg: null == msg
          ? _value.msg
          : msg // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DartCommand_Stdout implements DartCommand_Stdout {
  const _$DartCommand_Stdout({required this.msg});

  @override
  final String msg;

  @override
  String toString() {
    return 'DartCommand.stdout(msg: $msg)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DartCommand_Stdout &&
            (identical(other.msg, msg) || other.msg == msg));
  }

  @override
  int get hashCode => Object.hash(runtimeType, msg);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DartCommand_StdoutCopyWith<_$DartCommand_Stdout> get copyWith =>
      __$$DartCommand_StdoutCopyWithImpl<_$DartCommand_Stdout>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String msg) stdout,
    required TResult Function(String msg) stderr,
    required TResult Function(ButtonInfo info, DartRequestKey key) addButton,
    required TResult Function(LabelInfo info, DartRequestKey key) addLabel,
  }) {
    return stdout(msg);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String msg)? stdout,
    TResult? Function(String msg)? stderr,
    TResult? Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult? Function(LabelInfo info, DartRequestKey key)? addLabel,
  }) {
    return stdout?.call(msg);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String msg)? stdout,
    TResult Function(String msg)? stderr,
    TResult Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult Function(LabelInfo info, DartRequestKey key)? addLabel,
    required TResult orElse(),
  }) {
    if (stdout != null) {
      return stdout(msg);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DartCommand_Stdout value) stdout,
    required TResult Function(DartCommand_Stderr value) stderr,
    required TResult Function(DartCommand_AddButton value) addButton,
    required TResult Function(DartCommand_AddLabel value) addLabel,
  }) {
    return stdout(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DartCommand_Stdout value)? stdout,
    TResult? Function(DartCommand_Stderr value)? stderr,
    TResult? Function(DartCommand_AddButton value)? addButton,
    TResult? Function(DartCommand_AddLabel value)? addLabel,
  }) {
    return stdout?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DartCommand_Stdout value)? stdout,
    TResult Function(DartCommand_Stderr value)? stderr,
    TResult Function(DartCommand_AddButton value)? addButton,
    TResult Function(DartCommand_AddLabel value)? addLabel,
    required TResult orElse(),
  }) {
    if (stdout != null) {
      return stdout(this);
    }
    return orElse();
  }
}

abstract class DartCommand_Stdout implements DartCommand {
  const factory DartCommand_Stdout({required final String msg}) =
      _$DartCommand_Stdout;

  String get msg;
  @JsonKey(ignore: true)
  _$$DartCommand_StdoutCopyWith<_$DartCommand_Stdout> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DartCommand_StderrCopyWith<$Res> {
  factory _$$DartCommand_StderrCopyWith(_$DartCommand_Stderr value,
          $Res Function(_$DartCommand_Stderr) then) =
      __$$DartCommand_StderrCopyWithImpl<$Res>;
  @useResult
  $Res call({String msg});
}

/// @nodoc
class __$$DartCommand_StderrCopyWithImpl<$Res>
    extends _$DartCommandCopyWithImpl<$Res, _$DartCommand_Stderr>
    implements _$$DartCommand_StderrCopyWith<$Res> {
  __$$DartCommand_StderrCopyWithImpl(
      _$DartCommand_Stderr _value, $Res Function(_$DartCommand_Stderr) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msg = null,
  }) {
    return _then(_$DartCommand_Stderr(
      msg: null == msg
          ? _value.msg
          : msg // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DartCommand_Stderr implements DartCommand_Stderr {
  const _$DartCommand_Stderr({required this.msg});

  @override
  final String msg;

  @override
  String toString() {
    return 'DartCommand.stderr(msg: $msg)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DartCommand_Stderr &&
            (identical(other.msg, msg) || other.msg == msg));
  }

  @override
  int get hashCode => Object.hash(runtimeType, msg);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DartCommand_StderrCopyWith<_$DartCommand_Stderr> get copyWith =>
      __$$DartCommand_StderrCopyWithImpl<_$DartCommand_Stderr>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String msg) stdout,
    required TResult Function(String msg) stderr,
    required TResult Function(ButtonInfo info, DartRequestKey key) addButton,
    required TResult Function(LabelInfo info, DartRequestKey key) addLabel,
  }) {
    return stderr(msg);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String msg)? stdout,
    TResult? Function(String msg)? stderr,
    TResult? Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult? Function(LabelInfo info, DartRequestKey key)? addLabel,
  }) {
    return stderr?.call(msg);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String msg)? stdout,
    TResult Function(String msg)? stderr,
    TResult Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult Function(LabelInfo info, DartRequestKey key)? addLabel,
    required TResult orElse(),
  }) {
    if (stderr != null) {
      return stderr(msg);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DartCommand_Stdout value) stdout,
    required TResult Function(DartCommand_Stderr value) stderr,
    required TResult Function(DartCommand_AddButton value) addButton,
    required TResult Function(DartCommand_AddLabel value) addLabel,
  }) {
    return stderr(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DartCommand_Stdout value)? stdout,
    TResult? Function(DartCommand_Stderr value)? stderr,
    TResult? Function(DartCommand_AddButton value)? addButton,
    TResult? Function(DartCommand_AddLabel value)? addLabel,
  }) {
    return stderr?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DartCommand_Stdout value)? stdout,
    TResult Function(DartCommand_Stderr value)? stderr,
    TResult Function(DartCommand_AddButton value)? addButton,
    TResult Function(DartCommand_AddLabel value)? addLabel,
    required TResult orElse(),
  }) {
    if (stderr != null) {
      return stderr(this);
    }
    return orElse();
  }
}

abstract class DartCommand_Stderr implements DartCommand {
  const factory DartCommand_Stderr({required final String msg}) =
      _$DartCommand_Stderr;

  String get msg;
  @JsonKey(ignore: true)
  _$$DartCommand_StderrCopyWith<_$DartCommand_Stderr> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DartCommand_AddButtonCopyWith<$Res> {
  factory _$$DartCommand_AddButtonCopyWith(_$DartCommand_AddButton value,
          $Res Function(_$DartCommand_AddButton) then) =
      __$$DartCommand_AddButtonCopyWithImpl<$Res>;
  @useResult
  $Res call({ButtonInfo info, DartRequestKey key});
}

/// @nodoc
class __$$DartCommand_AddButtonCopyWithImpl<$Res>
    extends _$DartCommandCopyWithImpl<$Res, _$DartCommand_AddButton>
    implements _$$DartCommand_AddButtonCopyWith<$Res> {
  __$$DartCommand_AddButtonCopyWithImpl(_$DartCommand_AddButton _value,
      $Res Function(_$DartCommand_AddButton) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? info = null,
    Object? key = null,
  }) {
    return _then(_$DartCommand_AddButton(
      info: null == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as ButtonInfo,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as DartRequestKey,
    ));
  }
}

/// @nodoc

class _$DartCommand_AddButton implements DartCommand_AddButton {
  const _$DartCommand_AddButton({required this.info, required this.key});

  @override
  final ButtonInfo info;
  @override
  final DartRequestKey key;

  @override
  String toString() {
    return 'DartCommand.addButton(info: $info, key: $key)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DartCommand_AddButton &&
            (identical(other.info, info) || other.info == info) &&
            (identical(other.key, key) || other.key == key));
  }

  @override
  int get hashCode => Object.hash(runtimeType, info, key);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DartCommand_AddButtonCopyWith<_$DartCommand_AddButton> get copyWith =>
      __$$DartCommand_AddButtonCopyWithImpl<_$DartCommand_AddButton>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String msg) stdout,
    required TResult Function(String msg) stderr,
    required TResult Function(ButtonInfo info, DartRequestKey key) addButton,
    required TResult Function(LabelInfo info, DartRequestKey key) addLabel,
  }) {
    return addButton(info, key);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String msg)? stdout,
    TResult? Function(String msg)? stderr,
    TResult? Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult? Function(LabelInfo info, DartRequestKey key)? addLabel,
  }) {
    return addButton?.call(info, key);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String msg)? stdout,
    TResult Function(String msg)? stderr,
    TResult Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult Function(LabelInfo info, DartRequestKey key)? addLabel,
    required TResult orElse(),
  }) {
    if (addButton != null) {
      return addButton(info, key);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DartCommand_Stdout value) stdout,
    required TResult Function(DartCommand_Stderr value) stderr,
    required TResult Function(DartCommand_AddButton value) addButton,
    required TResult Function(DartCommand_AddLabel value) addLabel,
  }) {
    return addButton(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DartCommand_Stdout value)? stdout,
    TResult? Function(DartCommand_Stderr value)? stderr,
    TResult? Function(DartCommand_AddButton value)? addButton,
    TResult? Function(DartCommand_AddLabel value)? addLabel,
  }) {
    return addButton?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DartCommand_Stdout value)? stdout,
    TResult Function(DartCommand_Stderr value)? stderr,
    TResult Function(DartCommand_AddButton value)? addButton,
    TResult Function(DartCommand_AddLabel value)? addLabel,
    required TResult orElse(),
  }) {
    if (addButton != null) {
      return addButton(this);
    }
    return orElse();
  }
}

abstract class DartCommand_AddButton implements DartCommand {
  const factory DartCommand_AddButton(
      {required final ButtonInfo info,
      required final DartRequestKey key}) = _$DartCommand_AddButton;

  ButtonInfo get info;
  DartRequestKey get key;
  @JsonKey(ignore: true)
  _$$DartCommand_AddButtonCopyWith<_$DartCommand_AddButton> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DartCommand_AddLabelCopyWith<$Res> {
  factory _$$DartCommand_AddLabelCopyWith(_$DartCommand_AddLabel value,
          $Res Function(_$DartCommand_AddLabel) then) =
      __$$DartCommand_AddLabelCopyWithImpl<$Res>;
  @useResult
  $Res call({LabelInfo info, DartRequestKey key});
}

/// @nodoc
class __$$DartCommand_AddLabelCopyWithImpl<$Res>
    extends _$DartCommandCopyWithImpl<$Res, _$DartCommand_AddLabel>
    implements _$$DartCommand_AddLabelCopyWith<$Res> {
  __$$DartCommand_AddLabelCopyWithImpl(_$DartCommand_AddLabel _value,
      $Res Function(_$DartCommand_AddLabel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? info = null,
    Object? key = null,
  }) {
    return _then(_$DartCommand_AddLabel(
      info: null == info
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as LabelInfo,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as DartRequestKey,
    ));
  }
}

/// @nodoc

class _$DartCommand_AddLabel implements DartCommand_AddLabel {
  const _$DartCommand_AddLabel({required this.info, required this.key});

  @override
  final LabelInfo info;
  @override
  final DartRequestKey key;

  @override
  String toString() {
    return 'DartCommand.addLabel(info: $info, key: $key)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DartCommand_AddLabel &&
            (identical(other.info, info) || other.info == info) &&
            (identical(other.key, key) || other.key == key));
  }

  @override
  int get hashCode => Object.hash(runtimeType, info, key);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DartCommand_AddLabelCopyWith<_$DartCommand_AddLabel> get copyWith =>
      __$$DartCommand_AddLabelCopyWithImpl<_$DartCommand_AddLabel>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String msg) stdout,
    required TResult Function(String msg) stderr,
    required TResult Function(ButtonInfo info, DartRequestKey key) addButton,
    required TResult Function(LabelInfo info, DartRequestKey key) addLabel,
  }) {
    return addLabel(info, key);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String msg)? stdout,
    TResult? Function(String msg)? stderr,
    TResult? Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult? Function(LabelInfo info, DartRequestKey key)? addLabel,
  }) {
    return addLabel?.call(info, key);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String msg)? stdout,
    TResult Function(String msg)? stderr,
    TResult Function(ButtonInfo info, DartRequestKey key)? addButton,
    TResult Function(LabelInfo info, DartRequestKey key)? addLabel,
    required TResult orElse(),
  }) {
    if (addLabel != null) {
      return addLabel(info, key);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DartCommand_Stdout value) stdout,
    required TResult Function(DartCommand_Stderr value) stderr,
    required TResult Function(DartCommand_AddButton value) addButton,
    required TResult Function(DartCommand_AddLabel value) addLabel,
  }) {
    return addLabel(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DartCommand_Stdout value)? stdout,
    TResult? Function(DartCommand_Stderr value)? stderr,
    TResult? Function(DartCommand_AddButton value)? addButton,
    TResult? Function(DartCommand_AddLabel value)? addLabel,
  }) {
    return addLabel?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DartCommand_Stdout value)? stdout,
    TResult Function(DartCommand_Stderr value)? stderr,
    TResult Function(DartCommand_AddButton value)? addButton,
    TResult Function(DartCommand_AddLabel value)? addLabel,
    required TResult orElse(),
  }) {
    if (addLabel != null) {
      return addLabel(this);
    }
    return orElse();
  }
}

abstract class DartCommand_AddLabel implements DartCommand {
  const factory DartCommand_AddLabel(
      {required final LabelInfo info,
      required final DartRequestKey key}) = _$DartCommand_AddLabel;

  LabelInfo get info;
  DartRequestKey get key;
  @JsonKey(ignore: true)
  _$$DartCommand_AddLabelCopyWith<_$DartCommand_AddLabel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RequestResult {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SimpleValue field0) ok,
    required TResult Function(String field0) err,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SimpleValue field0)? ok,
    TResult? Function(String field0)? err,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SimpleValue field0)? ok,
    TResult Function(String field0)? err,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RequestResult_Ok value) ok,
    required TResult Function(RequestResult_Err value) err,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RequestResult_Ok value)? ok,
    TResult? Function(RequestResult_Err value)? err,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RequestResult_Ok value)? ok,
    TResult Function(RequestResult_Err value)? err,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequestResultCopyWith<$Res> {
  factory $RequestResultCopyWith(
          RequestResult value, $Res Function(RequestResult) then) =
      _$RequestResultCopyWithImpl<$Res, RequestResult>;
}

/// @nodoc
class _$RequestResultCopyWithImpl<$Res, $Val extends RequestResult>
    implements $RequestResultCopyWith<$Res> {
  _$RequestResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$RequestResult_OkCopyWith<$Res> {
  factory _$$RequestResult_OkCopyWith(
          _$RequestResult_Ok value, $Res Function(_$RequestResult_Ok) then) =
      __$$RequestResult_OkCopyWithImpl<$Res>;
  @useResult
  $Res call({SimpleValue field0});

  $SimpleValueCopyWith<$Res> get field0;
}

/// @nodoc
class __$$RequestResult_OkCopyWithImpl<$Res>
    extends _$RequestResultCopyWithImpl<$Res, _$RequestResult_Ok>
    implements _$$RequestResult_OkCopyWith<$Res> {
  __$$RequestResult_OkCopyWithImpl(
      _$RequestResult_Ok _value, $Res Function(_$RequestResult_Ok) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$RequestResult_Ok(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as SimpleValue,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $SimpleValueCopyWith<$Res> get field0 {
    return $SimpleValueCopyWith<$Res>(_value.field0, (value) {
      return _then(_value.copyWith(field0: value));
    });
  }
}

/// @nodoc

class _$RequestResult_Ok implements RequestResult_Ok {
  const _$RequestResult_Ok(this.field0);

  @override
  final SimpleValue field0;

  @override
  String toString() {
    return 'RequestResult.ok(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestResult_Ok &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RequestResult_OkCopyWith<_$RequestResult_Ok> get copyWith =>
      __$$RequestResult_OkCopyWithImpl<_$RequestResult_Ok>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SimpleValue field0) ok,
    required TResult Function(String field0) err,
  }) {
    return ok(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SimpleValue field0)? ok,
    TResult? Function(String field0)? err,
  }) {
    return ok?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SimpleValue field0)? ok,
    TResult Function(String field0)? err,
    required TResult orElse(),
  }) {
    if (ok != null) {
      return ok(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RequestResult_Ok value) ok,
    required TResult Function(RequestResult_Err value) err,
  }) {
    return ok(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RequestResult_Ok value)? ok,
    TResult? Function(RequestResult_Err value)? err,
  }) {
    return ok?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RequestResult_Ok value)? ok,
    TResult Function(RequestResult_Err value)? err,
    required TResult orElse(),
  }) {
    if (ok != null) {
      return ok(this);
    }
    return orElse();
  }
}

abstract class RequestResult_Ok implements RequestResult {
  const factory RequestResult_Ok(final SimpleValue field0) = _$RequestResult_Ok;

  @override
  SimpleValue get field0;
  @JsonKey(ignore: true)
  _$$RequestResult_OkCopyWith<_$RequestResult_Ok> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RequestResult_ErrCopyWith<$Res> {
  factory _$$RequestResult_ErrCopyWith(
          _$RequestResult_Err value, $Res Function(_$RequestResult_Err) then) =
      __$$RequestResult_ErrCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$RequestResult_ErrCopyWithImpl<$Res>
    extends _$RequestResultCopyWithImpl<$Res, _$RequestResult_Err>
    implements _$$RequestResult_ErrCopyWith<$Res> {
  __$$RequestResult_ErrCopyWithImpl(
      _$RequestResult_Err _value, $Res Function(_$RequestResult_Err) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$RequestResult_Err(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RequestResult_Err implements RequestResult_Err {
  const _$RequestResult_Err(this.field0);

  @override
  final String field0;

  @override
  String toString() {
    return 'RequestResult.err(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestResult_Err &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RequestResult_ErrCopyWith<_$RequestResult_Err> get copyWith =>
      __$$RequestResult_ErrCopyWithImpl<_$RequestResult_Err>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SimpleValue field0) ok,
    required TResult Function(String field0) err,
  }) {
    return err(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SimpleValue field0)? ok,
    TResult? Function(String field0)? err,
  }) {
    return err?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SimpleValue field0)? ok,
    TResult Function(String field0)? err,
    required TResult orElse(),
  }) {
    if (err != null) {
      return err(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RequestResult_Ok value) ok,
    required TResult Function(RequestResult_Err value) err,
  }) {
    return err(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RequestResult_Ok value)? ok,
    TResult? Function(RequestResult_Err value)? err,
  }) {
    return err?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RequestResult_Ok value)? ok,
    TResult Function(RequestResult_Err value)? err,
    required TResult orElse(),
  }) {
    if (err != null) {
      return err(this);
    }
    return orElse();
  }
}

abstract class RequestResult_Err implements RequestResult {
  const factory RequestResult_Err(final String field0) = _$RequestResult_Err;

  @override
  String get field0;
  @JsonKey(ignore: true)
  _$$RequestResult_ErrCopyWith<_$RequestResult_Err> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RustCommand {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String xml) setProject,
    required TResult Function() start,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String xml)? setProject,
    TResult? Function()? start,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String xml)? setProject,
    TResult Function()? start,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RustCommand_SetProject value) setProject,
    required TResult Function(RustCommand_Start value) start,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RustCommand_SetProject value)? setProject,
    TResult? Function(RustCommand_Start value)? start,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RustCommand_SetProject value)? setProject,
    TResult Function(RustCommand_Start value)? start,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RustCommandCopyWith<$Res> {
  factory $RustCommandCopyWith(
          RustCommand value, $Res Function(RustCommand) then) =
      _$RustCommandCopyWithImpl<$Res, RustCommand>;
}

/// @nodoc
class _$RustCommandCopyWithImpl<$Res, $Val extends RustCommand>
    implements $RustCommandCopyWith<$Res> {
  _$RustCommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$RustCommand_SetProjectCopyWith<$Res> {
  factory _$$RustCommand_SetProjectCopyWith(_$RustCommand_SetProject value,
          $Res Function(_$RustCommand_SetProject) then) =
      __$$RustCommand_SetProjectCopyWithImpl<$Res>;
  @useResult
  $Res call({String xml});
}

/// @nodoc
class __$$RustCommand_SetProjectCopyWithImpl<$Res>
    extends _$RustCommandCopyWithImpl<$Res, _$RustCommand_SetProject>
    implements _$$RustCommand_SetProjectCopyWith<$Res> {
  __$$RustCommand_SetProjectCopyWithImpl(_$RustCommand_SetProject _value,
      $Res Function(_$RustCommand_SetProject) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? xml = null,
  }) {
    return _then(_$RustCommand_SetProject(
      xml: null == xml
          ? _value.xml
          : xml // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RustCommand_SetProject implements RustCommand_SetProject {
  const _$RustCommand_SetProject({required this.xml});

  @override
  final String xml;

  @override
  String toString() {
    return 'RustCommand.setProject(xml: $xml)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RustCommand_SetProject &&
            (identical(other.xml, xml) || other.xml == xml));
  }

  @override
  int get hashCode => Object.hash(runtimeType, xml);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RustCommand_SetProjectCopyWith<_$RustCommand_SetProject> get copyWith =>
      __$$RustCommand_SetProjectCopyWithImpl<_$RustCommand_SetProject>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String xml) setProject,
    required TResult Function() start,
  }) {
    return setProject(xml);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String xml)? setProject,
    TResult? Function()? start,
  }) {
    return setProject?.call(xml);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String xml)? setProject,
    TResult Function()? start,
    required TResult orElse(),
  }) {
    if (setProject != null) {
      return setProject(xml);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RustCommand_SetProject value) setProject,
    required TResult Function(RustCommand_Start value) start,
  }) {
    return setProject(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RustCommand_SetProject value)? setProject,
    TResult? Function(RustCommand_Start value)? start,
  }) {
    return setProject?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RustCommand_SetProject value)? setProject,
    TResult Function(RustCommand_Start value)? start,
    required TResult orElse(),
  }) {
    if (setProject != null) {
      return setProject(this);
    }
    return orElse();
  }
}

abstract class RustCommand_SetProject implements RustCommand {
  const factory RustCommand_SetProject({required final String xml}) =
      _$RustCommand_SetProject;

  String get xml;
  @JsonKey(ignore: true)
  _$$RustCommand_SetProjectCopyWith<_$RustCommand_SetProject> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RustCommand_StartCopyWith<$Res> {
  factory _$$RustCommand_StartCopyWith(
          _$RustCommand_Start value, $Res Function(_$RustCommand_Start) then) =
      __$$RustCommand_StartCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RustCommand_StartCopyWithImpl<$Res>
    extends _$RustCommandCopyWithImpl<$Res, _$RustCommand_Start>
    implements _$$RustCommand_StartCopyWith<$Res> {
  __$$RustCommand_StartCopyWithImpl(
      _$RustCommand_Start _value, $Res Function(_$RustCommand_Start) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RustCommand_Start implements RustCommand_Start {
  const _$RustCommand_Start();

  @override
  String toString() {
    return 'RustCommand.start()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RustCommand_Start);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String xml) setProject,
    required TResult Function() start,
  }) {
    return start();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String xml)? setProject,
    TResult? Function()? start,
  }) {
    return start?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String xml)? setProject,
    TResult Function()? start,
    required TResult orElse(),
  }) {
    if (start != null) {
      return start();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RustCommand_SetProject value) setProject,
    required TResult Function(RustCommand_Start value) start,
  }) {
    return start(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RustCommand_SetProject value)? setProject,
    TResult? Function(RustCommand_Start value)? start,
  }) {
    return start?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RustCommand_SetProject value)? setProject,
    TResult Function(RustCommand_Start value)? start,
    required TResult orElse(),
  }) {
    if (start != null) {
      return start(this);
    }
    return orElse();
  }
}

abstract class RustCommand_Start implements RustCommand {
  const factory RustCommand_Start() = _$RustCommand_Start;
}

/// @nodoc
mixin _$SimpleValue {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double field0) number,
    required TResult Function(String field0) string,
    required TResult Function(List<SimpleValue> field0) list,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double field0)? number,
    TResult? Function(String field0)? string,
    TResult? Function(List<SimpleValue> field0)? list,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double field0)? number,
    TResult Function(String field0)? string,
    TResult Function(List<SimpleValue> field0)? list,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SimpleValue_Number value) number,
    required TResult Function(SimpleValue_String value) string,
    required TResult Function(SimpleValue_List value) list,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SimpleValue_Number value)? number,
    TResult? Function(SimpleValue_String value)? string,
    TResult? Function(SimpleValue_List value)? list,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SimpleValue_Number value)? number,
    TResult Function(SimpleValue_String value)? string,
    TResult Function(SimpleValue_List value)? list,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimpleValueCopyWith<$Res> {
  factory $SimpleValueCopyWith(
          SimpleValue value, $Res Function(SimpleValue) then) =
      _$SimpleValueCopyWithImpl<$Res, SimpleValue>;
}

/// @nodoc
class _$SimpleValueCopyWithImpl<$Res, $Val extends SimpleValue>
    implements $SimpleValueCopyWith<$Res> {
  _$SimpleValueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$SimpleValue_NumberCopyWith<$Res> {
  factory _$$SimpleValue_NumberCopyWith(_$SimpleValue_Number value,
          $Res Function(_$SimpleValue_Number) then) =
      __$$SimpleValue_NumberCopyWithImpl<$Res>;
  @useResult
  $Res call({double field0});
}

/// @nodoc
class __$$SimpleValue_NumberCopyWithImpl<$Res>
    extends _$SimpleValueCopyWithImpl<$Res, _$SimpleValue_Number>
    implements _$$SimpleValue_NumberCopyWith<$Res> {
  __$$SimpleValue_NumberCopyWithImpl(
      _$SimpleValue_Number _value, $Res Function(_$SimpleValue_Number) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$SimpleValue_Number(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$SimpleValue_Number implements SimpleValue_Number {
  const _$SimpleValue_Number(this.field0);

  @override
  final double field0;

  @override
  String toString() {
    return 'SimpleValue.number(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimpleValue_Number &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SimpleValue_NumberCopyWith<_$SimpleValue_Number> get copyWith =>
      __$$SimpleValue_NumberCopyWithImpl<_$SimpleValue_Number>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double field0) number,
    required TResult Function(String field0) string,
    required TResult Function(List<SimpleValue> field0) list,
  }) {
    return number(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double field0)? number,
    TResult? Function(String field0)? string,
    TResult? Function(List<SimpleValue> field0)? list,
  }) {
    return number?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double field0)? number,
    TResult Function(String field0)? string,
    TResult Function(List<SimpleValue> field0)? list,
    required TResult orElse(),
  }) {
    if (number != null) {
      return number(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SimpleValue_Number value) number,
    required TResult Function(SimpleValue_String value) string,
    required TResult Function(SimpleValue_List value) list,
  }) {
    return number(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SimpleValue_Number value)? number,
    TResult? Function(SimpleValue_String value)? string,
    TResult? Function(SimpleValue_List value)? list,
  }) {
    return number?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SimpleValue_Number value)? number,
    TResult Function(SimpleValue_String value)? string,
    TResult Function(SimpleValue_List value)? list,
    required TResult orElse(),
  }) {
    if (number != null) {
      return number(this);
    }
    return orElse();
  }
}

abstract class SimpleValue_Number implements SimpleValue {
  const factory SimpleValue_Number(final double field0) = _$SimpleValue_Number;

  @override
  double get field0;
  @JsonKey(ignore: true)
  _$$SimpleValue_NumberCopyWith<_$SimpleValue_Number> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SimpleValue_StringCopyWith<$Res> {
  factory _$$SimpleValue_StringCopyWith(_$SimpleValue_String value,
          $Res Function(_$SimpleValue_String) then) =
      __$$SimpleValue_StringCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$SimpleValue_StringCopyWithImpl<$Res>
    extends _$SimpleValueCopyWithImpl<$Res, _$SimpleValue_String>
    implements _$$SimpleValue_StringCopyWith<$Res> {
  __$$SimpleValue_StringCopyWithImpl(
      _$SimpleValue_String _value, $Res Function(_$SimpleValue_String) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$SimpleValue_String(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SimpleValue_String implements SimpleValue_String {
  const _$SimpleValue_String(this.field0);

  @override
  final String field0;

  @override
  String toString() {
    return 'SimpleValue.string(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimpleValue_String &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SimpleValue_StringCopyWith<_$SimpleValue_String> get copyWith =>
      __$$SimpleValue_StringCopyWithImpl<_$SimpleValue_String>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double field0) number,
    required TResult Function(String field0) string,
    required TResult Function(List<SimpleValue> field0) list,
  }) {
    return string(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double field0)? number,
    TResult? Function(String field0)? string,
    TResult? Function(List<SimpleValue> field0)? list,
  }) {
    return string?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double field0)? number,
    TResult Function(String field0)? string,
    TResult Function(List<SimpleValue> field0)? list,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SimpleValue_Number value) number,
    required TResult Function(SimpleValue_String value) string,
    required TResult Function(SimpleValue_List value) list,
  }) {
    return string(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SimpleValue_Number value)? number,
    TResult? Function(SimpleValue_String value)? string,
    TResult? Function(SimpleValue_List value)? list,
  }) {
    return string?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SimpleValue_Number value)? number,
    TResult Function(SimpleValue_String value)? string,
    TResult Function(SimpleValue_List value)? list,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(this);
    }
    return orElse();
  }
}

abstract class SimpleValue_String implements SimpleValue {
  const factory SimpleValue_String(final String field0) = _$SimpleValue_String;

  @override
  String get field0;
  @JsonKey(ignore: true)
  _$$SimpleValue_StringCopyWith<_$SimpleValue_String> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SimpleValue_ListCopyWith<$Res> {
  factory _$$SimpleValue_ListCopyWith(
          _$SimpleValue_List value, $Res Function(_$SimpleValue_List) then) =
      __$$SimpleValue_ListCopyWithImpl<$Res>;
  @useResult
  $Res call({List<SimpleValue> field0});
}

/// @nodoc
class __$$SimpleValue_ListCopyWithImpl<$Res>
    extends _$SimpleValueCopyWithImpl<$Res, _$SimpleValue_List>
    implements _$$SimpleValue_ListCopyWith<$Res> {
  __$$SimpleValue_ListCopyWithImpl(
      _$SimpleValue_List _value, $Res Function(_$SimpleValue_List) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$SimpleValue_List(
      null == field0
          ? _value._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<SimpleValue>,
    ));
  }
}

/// @nodoc

class _$SimpleValue_List implements SimpleValue_List {
  const _$SimpleValue_List(final List<SimpleValue> field0) : _field0 = field0;

  final List<SimpleValue> _field0;
  @override
  List<SimpleValue> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  @override
  String toString() {
    return 'SimpleValue.list(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimpleValue_List &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SimpleValue_ListCopyWith<_$SimpleValue_List> get copyWith =>
      __$$SimpleValue_ListCopyWithImpl<_$SimpleValue_List>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double field0) number,
    required TResult Function(String field0) string,
    required TResult Function(List<SimpleValue> field0) list,
  }) {
    return list(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double field0)? number,
    TResult? Function(String field0)? string,
    TResult? Function(List<SimpleValue> field0)? list,
  }) {
    return list?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double field0)? number,
    TResult Function(String field0)? string,
    TResult Function(List<SimpleValue> field0)? list,
    required TResult orElse(),
  }) {
    if (list != null) {
      return list(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SimpleValue_Number value) number,
    required TResult Function(SimpleValue_String value) string,
    required TResult Function(SimpleValue_List value) list,
  }) {
    return list(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SimpleValue_Number value)? number,
    TResult? Function(SimpleValue_String value)? string,
    TResult? Function(SimpleValue_List value)? list,
  }) {
    return list?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SimpleValue_Number value)? number,
    TResult Function(SimpleValue_String value)? string,
    TResult Function(SimpleValue_List value)? list,
    required TResult orElse(),
  }) {
    if (list != null) {
      return list(this);
    }
    return orElse();
  }
}

abstract class SimpleValue_List implements SimpleValue {
  const factory SimpleValue_List(final List<SimpleValue> field0) =
      _$SimpleValue_List;

  @override
  List<SimpleValue> get field0;
  @JsonKey(ignore: true)
  _$$SimpleValue_ListCopyWith<_$SimpleValue_List> get copyWith =>
      throw _privateConstructorUsedError;
}
