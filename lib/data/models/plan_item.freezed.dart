// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanWhen {

@DateOnlyConverter() DateTime get from;@DateOnlyConverter() DateTime get to;
/// Create a copy of PlanWhen
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanWhenCopyWith<PlanWhen> get copyWith => _$PlanWhenCopyWithImpl<PlanWhen>(this as PlanWhen, _$identity);

  /// Serializes this PlanWhen to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanWhen;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanWhen&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanWhen;
  return Object.hash(runtimeType,_this.from,_this.to);
}

@override
String toString() {
  final _this = this as PlanWhen;
  return 'PlanWhen(from: ${_this.from}, to: ${_this.to})';
}


}

/// @nodoc
abstract mixin class $PlanWhenCopyWith<$Res>  {
  factory $PlanWhenCopyWith(PlanWhen value, $Res Function(PlanWhen) _then) = _$PlanWhenCopyWithImpl;
@useResult
$Res call({
@DateOnlyConverter() DateTime from,@DateOnlyConverter() DateTime to
});




}
/// @nodoc
class _$PlanWhenCopyWithImpl<$Res>
    implements $PlanWhenCopyWith<$Res> {
  _$PlanWhenCopyWithImpl(this._self, this._then);

  final PlanWhen _self;
  final $Res Function(PlanWhen) _then;

/// Create a copy of PlanWhen
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,}) {
  return _then(PlanWhen(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanWhen].
extension PlanWhenPatterns on PlanWhen {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanWhen value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanWhen() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanWhen value)  $default,){
final _that = this;
switch (_that) {
case _PlanWhen():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanWhen value)?  $default,){
final _that = this;
switch (_that) {
case _PlanWhen() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime from, @DateOnlyConverter()  DateTime to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanWhen() when $default != null:
return $default(_that.from,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DateOnlyConverter()  DateTime from, @DateOnlyConverter()  DateTime to)  $default,) {final _that = this;
switch (_that) {
case _PlanWhen():
return $default(_that.from,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DateOnlyConverter()  DateTime from, @DateOnlyConverter()  DateTime to)?  $default,) {final _that = this;
switch (_that) {
case _PlanWhen() when $default != null:
return $default(_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanWhen extends PlanWhen {
  const _PlanWhen({@DateOnlyConverter() required this.from, @DateOnlyConverter() required this.to}): super._();
  factory _PlanWhen.fromJson(Map<String, dynamic> json) => _$PlanWhenFromJson(json);

@override@DateOnlyConverter() final  DateTime from;
@override@DateOnlyConverter() final  DateTime to;

/// Create a copy of PlanWhen
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanWhenCopyWith<_PlanWhen> get copyWith => __$PlanWhenCopyWithImpl<_PlanWhen>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanWhenToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanWhen&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,from,to);
}

@override
String toString() {
    return 'PlanWhen(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$PlanWhenCopyWith<$Res> implements $PlanWhenCopyWith<$Res> {
  factory _$PlanWhenCopyWith(_PlanWhen value, $Res Function(_PlanWhen) _then) = __$PlanWhenCopyWithImpl;
@override @useResult
$Res call({
@DateOnlyConverter() DateTime from,@DateOnlyConverter() DateTime to
});




}
/// @nodoc
class __$PlanWhenCopyWithImpl<$Res>
    implements _$PlanWhenCopyWith<$Res> {
  __$PlanWhenCopyWithImpl(this._self, this._then);

  final _PlanWhen _self;
  final $Res Function(_PlanWhen) _then;

/// Create a copy of PlanWhen
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(_PlanWhen(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$PlanItem {

 String get entry; bool get done; bool get repeat; String get note; PlanWhen? get when;
/// Create a copy of PlanItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanItemCopyWith<PlanItem> get copyWith => _$PlanItemCopyWithImpl<PlanItem>(this as PlanItem, _$identity);

  /// Serializes this PlanItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanItem&&(identical(other.entry, _this.entry) || other.entry == _this.entry)&&(identical(other.done, _this.done) || other.done == _this.done)&&(identical(other.repeat, _this.repeat) || other.repeat == _this.repeat)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.when, _this.when) || other.when == _this.when));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanItem;
  return Object.hash(runtimeType,_this.entry,_this.done,_this.repeat,_this.note,_this.when);
}

@override
String toString() {
  final _this = this as PlanItem;
  return 'PlanItem(entry: ${_this.entry}, done: ${_this.done}, repeat: ${_this.repeat}, note: ${_this.note}, when: ${_this.when})';
}


}

/// @nodoc
abstract mixin class $PlanItemCopyWith<$Res>  {
  factory $PlanItemCopyWith(PlanItem value, $Res Function(PlanItem) _then) = _$PlanItemCopyWithImpl;
@useResult
$Res call({
 String entry, bool done, bool repeat, String note, PlanWhen? when
});


$PlanWhenCopyWith<$Res>? get when;

}
/// @nodoc
class _$PlanItemCopyWithImpl<$Res>
    implements $PlanItemCopyWith<$Res> {
  _$PlanItemCopyWithImpl(this._self, this._then);

  final PlanItem _self;
  final $Res Function(PlanItem) _then;

/// Create a copy of PlanItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entry = null,Object? done = null,Object? repeat = null,Object? note = null,Object? when = freezed,}) {
  return _then(PlanItem(
entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as String,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,when: freezed == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as PlanWhen?,
  ));
}
/// Create a copy of PlanItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanWhenCopyWith<$Res>? get when {
    if (_self.when == null) {
    return null;
  }

  return $PlanWhenCopyWith<$Res>(_self.when!, (value) {
    return _then(_self.copyWith(when: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanItem].
extension PlanItemPatterns on PlanItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanItem value)  $default,){
final _that = this;
switch (_that) {
case _PlanItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanItem value)?  $default,){
final _that = this;
switch (_that) {
case _PlanItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entry,  bool done,  bool repeat,  String note,  PlanWhen? when)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanItem() when $default != null:
return $default(_that.entry,_that.done,_that.repeat,_that.note,_that.when);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entry,  bool done,  bool repeat,  String note,  PlanWhen? when)  $default,) {final _that = this;
switch (_that) {
case _PlanItem():
return $default(_that.entry,_that.done,_that.repeat,_that.note,_that.when);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entry,  bool done,  bool repeat,  String note,  PlanWhen? when)?  $default,) {final _that = this;
switch (_that) {
case _PlanItem() when $default != null:
return $default(_that.entry,_that.done,_that.repeat,_that.note,_that.when);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanItem implements PlanItem {
  const _PlanItem({required this.entry, this.done = false, this.repeat = false, this.note = '', this.when});
  factory _PlanItem.fromJson(Map<String, dynamic> json) => _$PlanItemFromJson(json);

@override final  String entry;
@override@JsonKey() final  bool done;
@override@JsonKey() final  bool repeat;
@override@JsonKey() final  String note;
@override final  PlanWhen? when;

/// Create a copy of PlanItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanItemCopyWith<_PlanItem> get copyWith => __$PlanItemCopyWithImpl<_PlanItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanItem&&(identical(other.entry, entry) || other.entry == entry)&&(identical(other.done, done) || other.done == done)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.note, note) || other.note == note)&&(identical(other.when, when) || other.when == when));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,entry,done,repeat,note,when);
}

@override
String toString() {
    return 'PlanItem(entry: $entry, done: $done, repeat: $repeat, note: $note, when: $when)';
}


}

/// @nodoc
abstract mixin class _$PlanItemCopyWith<$Res> implements $PlanItemCopyWith<$Res> {
  factory _$PlanItemCopyWith(_PlanItem value, $Res Function(_PlanItem) _then) = __$PlanItemCopyWithImpl;
@override @useResult
$Res call({
 String entry, bool done, bool repeat, String note, PlanWhen? when
});


@override $PlanWhenCopyWith<$Res>? get when;

}
/// @nodoc
class __$PlanItemCopyWithImpl<$Res>
    implements _$PlanItemCopyWith<$Res> {
  __$PlanItemCopyWithImpl(this._self, this._then);

  final _PlanItem _self;
  final $Res Function(_PlanItem) _then;

/// Create a copy of PlanItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entry = null,Object? done = null,Object? repeat = null,Object? note = null,Object? when = freezed,}) {
  return _then(_PlanItem(
entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as String,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,when: freezed == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as PlanWhen?,
  ));
}

/// Create a copy of PlanItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanWhenCopyWith<$Res>? get when {
    if (_self.when == null) {
    return null;
  }

  return $PlanWhenCopyWith<$Res>(_self.when!, (value) {
    return _then(_self.copyWith(when: value));
  });
}
}

// dart format on
