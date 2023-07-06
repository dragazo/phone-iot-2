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
mixin _$CustomControl {
  Object get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(CustomButton field0) button,
    required TResult Function(CustomLabel field0) label,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(CustomButton field0)? button,
    TResult? Function(CustomLabel field0)? label,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(CustomButton field0)? button,
    TResult Function(CustomLabel field0)? label,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CustomControl_Button value) button,
    required TResult Function(CustomControl_Label value) label,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CustomControl_Button value)? button,
    TResult? Function(CustomControl_Label value)? label,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CustomControl_Button value)? button,
    TResult Function(CustomControl_Label value)? label,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomControlCopyWith<$Res> {
  factory $CustomControlCopyWith(
          CustomControl value, $Res Function(CustomControl) then) =
      _$CustomControlCopyWithImpl<$Res, CustomControl>;
}

/// @nodoc
class _$CustomControlCopyWithImpl<$Res, $Val extends CustomControl>
    implements $CustomControlCopyWith<$Res> {
  _$CustomControlCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$CustomControl_ButtonCopyWith<$Res> {
  factory _$$CustomControl_ButtonCopyWith(_$CustomControl_Button value,
          $Res Function(_$CustomControl_Button) then) =
      __$$CustomControl_ButtonCopyWithImpl<$Res>;
  @useResult
  $Res call({CustomButton field0});
}

/// @nodoc
class __$$CustomControl_ButtonCopyWithImpl<$Res>
    extends _$CustomControlCopyWithImpl<$Res, _$CustomControl_Button>
    implements _$$CustomControl_ButtonCopyWith<$Res> {
  __$$CustomControl_ButtonCopyWithImpl(_$CustomControl_Button _value,
      $Res Function(_$CustomControl_Button) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$CustomControl_Button(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as CustomButton,
    ));
  }
}

/// @nodoc

class _$CustomControl_Button implements CustomControl_Button {
  const _$CustomControl_Button(this.field0);

  @override
  final CustomButton field0;

  @override
  String toString() {
    return 'CustomControl.button(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomControl_Button &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomControl_ButtonCopyWith<_$CustomControl_Button> get copyWith =>
      __$$CustomControl_ButtonCopyWithImpl<_$CustomControl_Button>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(CustomButton field0) button,
    required TResult Function(CustomLabel field0) label,
  }) {
    return button(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(CustomButton field0)? button,
    TResult? Function(CustomLabel field0)? label,
  }) {
    return button?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(CustomButton field0)? button,
    TResult Function(CustomLabel field0)? label,
    required TResult orElse(),
  }) {
    if (button != null) {
      return button(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CustomControl_Button value) button,
    required TResult Function(CustomControl_Label value) label,
  }) {
    return button(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CustomControl_Button value)? button,
    TResult? Function(CustomControl_Label value)? label,
  }) {
    return button?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CustomControl_Button value)? button,
    TResult Function(CustomControl_Label value)? label,
    required TResult orElse(),
  }) {
    if (button != null) {
      return button(this);
    }
    return orElse();
  }
}

abstract class CustomControl_Button implements CustomControl {
  const factory CustomControl_Button(final CustomButton field0) =
      _$CustomControl_Button;

  @override
  CustomButton get field0;
  @JsonKey(ignore: true)
  _$$CustomControl_ButtonCopyWith<_$CustomControl_Button> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CustomControl_LabelCopyWith<$Res> {
  factory _$$CustomControl_LabelCopyWith(_$CustomControl_Label value,
          $Res Function(_$CustomControl_Label) then) =
      __$$CustomControl_LabelCopyWithImpl<$Res>;
  @useResult
  $Res call({CustomLabel field0});
}

/// @nodoc
class __$$CustomControl_LabelCopyWithImpl<$Res>
    extends _$CustomControlCopyWithImpl<$Res, _$CustomControl_Label>
    implements _$$CustomControl_LabelCopyWith<$Res> {
  __$$CustomControl_LabelCopyWithImpl(
      _$CustomControl_Label _value, $Res Function(_$CustomControl_Label) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$CustomControl_Label(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as CustomLabel,
    ));
  }
}

/// @nodoc

class _$CustomControl_Label implements CustomControl_Label {
  const _$CustomControl_Label(this.field0);

  @override
  final CustomLabel field0;

  @override
  String toString() {
    return 'CustomControl.label(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomControl_Label &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomControl_LabelCopyWith<_$CustomControl_Label> get copyWith =>
      __$$CustomControl_LabelCopyWithImpl<_$CustomControl_Label>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(CustomButton field0) button,
    required TResult Function(CustomLabel field0) label,
  }) {
    return label(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(CustomButton field0)? button,
    TResult? Function(CustomLabel field0)? label,
  }) {
    return label?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(CustomButton field0)? button,
    TResult Function(CustomLabel field0)? label,
    required TResult orElse(),
  }) {
    if (label != null) {
      return label(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CustomControl_Button value) button,
    required TResult Function(CustomControl_Label value) label,
  }) {
    return label(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CustomControl_Button value)? button,
    TResult? Function(CustomControl_Label value)? label,
  }) {
    return label?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CustomControl_Button value)? button,
    TResult Function(CustomControl_Label value)? label,
    required TResult orElse(),
  }) {
    if (label != null) {
      return label(this);
    }
    return orElse();
  }
}

abstract class CustomControl_Label implements CustomControl {
  const factory CustomControl_Label(final CustomLabel field0) =
      _$CustomControl_Label;

  @override
  CustomLabel get field0;
  @JsonKey(ignore: true)
  _$$CustomControl_LabelCopyWith<_$CustomControl_Label> get copyWith =>
      throw _privateConstructorUsedError;
}
