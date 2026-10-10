// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Library {

 int get version; Map<TagCategory, List<String>> get tags; List<Entry> get entries; List<Plan> get plans;
/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryCopyWith<Library> get copyWith => _$LibraryCopyWithImpl<Library>(this as Library, _$identity);

  /// Serializes this Library to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Library;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Library&&(identical(other.version, _this.version) || other.version == _this.version)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.plans, _this.plans));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Library;
  return Object.hash(runtimeType,_this.version,const DeepCollectionEquality().hash(_this.tags),const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.plans));
}

@override
String toString() {
  final _this = this as Library;
  return 'Library(version: ${_this.version}, tags: ${_this.tags}, entries: ${_this.entries}, plans: ${_this.plans})';
}


}

/// @nodoc
abstract mixin class $LibraryCopyWith<$Res>  {
  factory $LibraryCopyWith(Library value, $Res Function(Library) _then) = _$LibraryCopyWithImpl;
@useResult
$Res call({
 int version, Map<TagCategory, List<String>> tags, List<Entry> entries, List<Plan> plans
});




}
/// @nodoc
class _$LibraryCopyWithImpl<$Res>
    implements $LibraryCopyWith<$Res> {
  _$LibraryCopyWithImpl(this._self, this._then);

  final Library _self;
  final $Res Function(Library) _then;

/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? tags = null,Object? entries = null,Object? plans = null,}) {
  return _then(Library(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as Map<TagCategory, List<String>>,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<Entry>,plans: null == plans ? _self.plans : plans // ignore: cast_nullable_to_non_nullable
as List<Plan>,
  ));
}

}


/// Adds pattern-matching-related methods to [Library].
extension LibraryPatterns on Library {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Library value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Library() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Library value)  $default,){
final _that = this;
switch (_that) {
case _Library():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Library value)?  $default,){
final _that = this;
switch (_that) {
case _Library() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  Map<TagCategory, List<String>> tags,  List<Entry> entries,  List<Plan> plans)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Library() when $default != null:
return $default(_that.version,_that.tags,_that.entries,_that.plans);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  Map<TagCategory, List<String>> tags,  List<Entry> entries,  List<Plan> plans)  $default,) {final _that = this;
switch (_that) {
case _Library():
return $default(_that.version,_that.tags,_that.entries,_that.plans);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  Map<TagCategory, List<String>> tags,  List<Entry> entries,  List<Plan> plans)?  $default,) {final _that = this;
switch (_that) {
case _Library() when $default != null:
return $default(_that.version,_that.tags,_that.entries,_that.plans);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Library extends Library {
  const _Library({this.version = 2,  Map<TagCategory, List<String>> tags = const {},  List<Entry> entries = const [],  List<Plan> plans = const []}): _tags = tags,_entries = entries,_plans = plans,super._();
  factory _Library.fromJson(Map<String, dynamic> json) => _$LibraryFromJson(json);

@override@JsonKey() final  int version;
 final  Map<TagCategory, List<String>> _tags;
@override@JsonKey() Map<TagCategory, List<String>> get tags {
  if (_tags is EqualUnmodifiableMapView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tags);
}

 final  List<Entry> _entries;
@override@JsonKey() List<Entry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<Plan> _plans;
@override@JsonKey() List<Plan> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}


/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryCopyWith<_Library> get copyWith => __$LibraryCopyWithImpl<_Library>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Library&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.tags, _tags)&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.plans, _plans));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,version,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_plans));
}

@override
String toString() {
    return 'Library(version: $version, tags: $tags, entries: $entries, plans: $plans)';
}


}

/// @nodoc
abstract mixin class _$LibraryCopyWith<$Res> implements $LibraryCopyWith<$Res> {
  factory _$LibraryCopyWith(_Library value, $Res Function(_Library) _then) = __$LibraryCopyWithImpl;
@override @useResult
$Res call({
 int version, Map<TagCategory, List<String>> tags, List<Entry> entries, List<Plan> plans
});




}
/// @nodoc
class __$LibraryCopyWithImpl<$Res>
    implements _$LibraryCopyWith<$Res> {
  __$LibraryCopyWithImpl(this._self, this._then);

  final _Library _self;
  final $Res Function(_Library) _then;

/// Create a copy of Library
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? tags = null,Object? entries = null,Object? plans = null,}) {
  return _then(_Library(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as Map<TagCategory, List<String>>,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<Entry>,plans: null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<Plan>,
  ));
}


}

// dart format on
