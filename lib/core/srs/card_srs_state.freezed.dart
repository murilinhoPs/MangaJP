// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_srs_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardSrsState {

 double get easeFactor; double get intervalDays; int get repetitions; DateTime get dueAt; CardPhase get phase; String get engineId;
/// Create a copy of CardSrsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardSrsStateCopyWith<CardSrsState> get copyWith => _$CardSrsStateCopyWithImpl<CardSrsState>(this as CardSrsState, _$identity);

  /// Serializes this CardSrsState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CardSrsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardSrsState&&(identical(other.easeFactor, _this.easeFactor) || other.easeFactor == _this.easeFactor)&&(identical(other.intervalDays, _this.intervalDays) || other.intervalDays == _this.intervalDays)&&(identical(other.repetitions, _this.repetitions) || other.repetitions == _this.repetitions)&&(identical(other.dueAt, _this.dueAt) || other.dueAt == _this.dueAt)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.engineId, _this.engineId) || other.engineId == _this.engineId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CardSrsState;
  return Object.hash(runtimeType,_this.easeFactor,_this.intervalDays,_this.repetitions,_this.dueAt,_this.phase,_this.engineId);
}

@override
String toString() {
  final _this = this as CardSrsState;
  return 'CardSrsState(easeFactor: ${_this.easeFactor}, intervalDays: ${_this.intervalDays}, repetitions: ${_this.repetitions}, dueAt: ${_this.dueAt}, phase: ${_this.phase}, engineId: ${_this.engineId})';
}


}

/// @nodoc
abstract mixin class $CardSrsStateCopyWith<$Res>  {
  factory $CardSrsStateCopyWith(CardSrsState value, $Res Function(CardSrsState) _then) = _$CardSrsStateCopyWithImpl;
@useResult
$Res call({
 double easeFactor, double intervalDays, int repetitions, DateTime dueAt, CardPhase phase, String engineId
});




}
/// @nodoc
class _$CardSrsStateCopyWithImpl<$Res>
    implements $CardSrsStateCopyWith<$Res> {
  _$CardSrsStateCopyWithImpl(this._self, this._then);

  final CardSrsState _self;
  final $Res Function(CardSrsState) _then;

/// Create a copy of CardSrsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? easeFactor = null,Object? intervalDays = null,Object? repetitions = null,Object? dueAt = null,Object? phase = null,Object? engineId = null,}) {
  return _then(CardSrsState(
easeFactor: null == easeFactor ? _self.easeFactor : easeFactor // ignore: cast_nullable_to_non_nullable
as double,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as double,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,dueAt: null == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CardPhase,engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CardSrsState].
extension CardSrsStatePatterns on CardSrsState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardSrsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardSrsState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardSrsState value)  $default,){
final _that = this;
switch (_that) {
case _CardSrsState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardSrsState value)?  $default,){
final _that = this;
switch (_that) {
case _CardSrsState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double easeFactor,  double intervalDays,  int repetitions,  DateTime dueAt,  CardPhase phase,  String engineId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardSrsState() when $default != null:
return $default(_that.easeFactor,_that.intervalDays,_that.repetitions,_that.dueAt,_that.phase,_that.engineId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double easeFactor,  double intervalDays,  int repetitions,  DateTime dueAt,  CardPhase phase,  String engineId)  $default,) {final _that = this;
switch (_that) {
case _CardSrsState():
return $default(_that.easeFactor,_that.intervalDays,_that.repetitions,_that.dueAt,_that.phase,_that.engineId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double easeFactor,  double intervalDays,  int repetitions,  DateTime dueAt,  CardPhase phase,  String engineId)?  $default,) {final _that = this;
switch (_that) {
case _CardSrsState() when $default != null:
return $default(_that.easeFactor,_that.intervalDays,_that.repetitions,_that.dueAt,_that.phase,_that.engineId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardSrsState implements CardSrsState {
  const _CardSrsState({required this.easeFactor, required this.intervalDays, required this.repetitions, required this.dueAt, required this.phase, this.engineId = 'sm2-jr@1'});
  factory _CardSrsState.fromJson(Map<String, dynamic> json) => _$CardSrsStateFromJson(json);

@override final  double easeFactor;
@override final  double intervalDays;
@override final  int repetitions;
@override final  DateTime dueAt;
@override final  CardPhase phase;
@override@JsonKey() final  String engineId;

/// Create a copy of CardSrsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardSrsStateCopyWith<_CardSrsState> get copyWith => __$CardSrsStateCopyWithImpl<_CardSrsState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardSrsStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardSrsState&&(identical(other.easeFactor, easeFactor) || other.easeFactor == easeFactor)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.engineId, engineId) || other.engineId == engineId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,easeFactor,intervalDays,repetitions,dueAt,phase,engineId);
}

@override
String toString() {
    return 'CardSrsState(easeFactor: $easeFactor, intervalDays: $intervalDays, repetitions: $repetitions, dueAt: $dueAt, phase: $phase, engineId: $engineId)';
}


}

/// @nodoc
abstract mixin class _$CardSrsStateCopyWith<$Res> implements $CardSrsStateCopyWith<$Res> {
  factory _$CardSrsStateCopyWith(_CardSrsState value, $Res Function(_CardSrsState) _then) = __$CardSrsStateCopyWithImpl;
@override @useResult
$Res call({
 double easeFactor, double intervalDays, int repetitions, DateTime dueAt, CardPhase phase, String engineId
});




}
/// @nodoc
class __$CardSrsStateCopyWithImpl<$Res>
    implements _$CardSrsStateCopyWith<$Res> {
  __$CardSrsStateCopyWithImpl(this._self, this._then);

  final _CardSrsState _self;
  final $Res Function(_CardSrsState) _then;

/// Create a copy of CardSrsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? easeFactor = null,Object? intervalDays = null,Object? repetitions = null,Object? dueAt = null,Object? phase = null,Object? engineId = null,}) {
  return _then(_CardSrsState(
easeFactor: null == easeFactor ? _self.easeFactor : easeFactor // ignore: cast_nullable_to_non_nullable
as double,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as double,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,dueAt: null == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CardPhase,engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
