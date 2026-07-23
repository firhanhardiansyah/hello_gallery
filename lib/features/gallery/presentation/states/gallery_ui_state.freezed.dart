// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GalleryLoadState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryLoadState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GalleryLoadState()';
}


}

/// @nodoc
class $GalleryLoadStateCopyWith<$Res>  {
$GalleryLoadStateCopyWith(GalleryLoadState _, $Res Function(GalleryLoadState) __);
}


/// Adds pattern-matching-related methods to [GalleryLoadState].
extension GalleryLoadStatePatterns on GalleryLoadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GalleryInitial value)?  initial,TResult Function( GalleryLoading value)?  loading,TResult Function( GalleryReady value)?  ready,TResult Function( GalleryEmpty value)?  empty,TResult Function( GalleryError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GalleryInitial() when initial != null:
return initial(_that);case GalleryLoading() when loading != null:
return loading(_that);case GalleryReady() when ready != null:
return ready(_that);case GalleryEmpty() when empty != null:
return empty(_that);case GalleryError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GalleryInitial value)  initial,required TResult Function( GalleryLoading value)  loading,required TResult Function( GalleryReady value)  ready,required TResult Function( GalleryEmpty value)  empty,required TResult Function( GalleryError value)  error,}){
final _that = this;
switch (_that) {
case GalleryInitial():
return initial(_that);case GalleryLoading():
return loading(_that);case GalleryReady():
return ready(_that);case GalleryEmpty():
return empty(_that);case GalleryError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GalleryInitial value)?  initial,TResult? Function( GalleryLoading value)?  loading,TResult? Function( GalleryReady value)?  ready,TResult? Function( GalleryEmpty value)?  empty,TResult? Function( GalleryError value)?  error,}){
final _that = this;
switch (_that) {
case GalleryInitial() when initial != null:
return initial(_that);case GalleryLoading() when loading != null:
return loading(_that);case GalleryReady() when ready != null:
return ready(_that);case GalleryEmpty() when empty != null:
return empty(_that);case GalleryError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  ready,TResult Function()?  empty,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GalleryInitial() when initial != null:
return initial();case GalleryLoading() when loading != null:
return loading();case GalleryReady() when ready != null:
return ready();case GalleryEmpty() when empty != null:
return empty();case GalleryError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  ready,required TResult Function()  empty,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case GalleryInitial():
return initial();case GalleryLoading():
return loading();case GalleryReady():
return ready();case GalleryEmpty():
return empty();case GalleryError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  ready,TResult? Function()?  empty,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case GalleryInitial() when initial != null:
return initial();case GalleryLoading() when loading != null:
return loading();case GalleryReady() when ready != null:
return ready();case GalleryEmpty() when empty != null:
return empty();case GalleryError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class GalleryInitial implements GalleryLoadState {
  const GalleryInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GalleryLoadState.initial()';
}


}




/// @nodoc


class GalleryLoading implements GalleryLoadState {
  const GalleryLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GalleryLoadState.loading()';
}


}




/// @nodoc


class GalleryReady implements GalleryLoadState {
  const GalleryReady();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryReady);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GalleryLoadState.ready()';
}


}




/// @nodoc


class GalleryEmpty implements GalleryLoadState {
  const GalleryEmpty();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GalleryLoadState.empty()';
}


}




/// @nodoc


class GalleryError implements GalleryLoadState {
  const GalleryError(this.message);
  

 final  String message;

/// Create a copy of GalleryLoadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryErrorCopyWith<GalleryError> get copyWith => _$GalleryErrorCopyWithImpl<GalleryError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'GalleryLoadState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $GalleryErrorCopyWith<$Res> implements $GalleryLoadStateCopyWith<$Res> {
  factory $GalleryErrorCopyWith(GalleryError value, $Res Function(GalleryError) _then) = _$GalleryErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$GalleryErrorCopyWithImpl<$Res>
    implements $GalleryErrorCopyWith<$Res> {
  _$GalleryErrorCopyWithImpl(this._self, this._then);

  final GalleryError _self;
  final $Res Function(GalleryError) _then;

/// Create a copy of GalleryLoadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(GalleryError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$GalleryUiState {

 GalleryLoadState get loadState; String? get rootPath; String? get currentPath; List<GalleryItem> get items; int get visibleCount; GallerySort get sort; bool get canGoBack; bool get canGoForward;
/// Create a copy of GalleryUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryUiStateCopyWith<GalleryUiState> get copyWith => _$GalleryUiStateCopyWithImpl<GalleryUiState>(this as GalleryUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryUiState&&(identical(other.loadState, loadState) || other.loadState == loadState)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.currentPath, currentPath) || other.currentPath == currentPath)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.visibleCount, visibleCount) || other.visibleCount == visibleCount)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.canGoBack, canGoBack) || other.canGoBack == canGoBack)&&(identical(other.canGoForward, canGoForward) || other.canGoForward == canGoForward));
}


@override
int get hashCode => Object.hash(runtimeType,loadState,rootPath,currentPath,const DeepCollectionEquality().hash(items),visibleCount,sort,canGoBack,canGoForward);

@override
String toString() {
  return 'GalleryUiState(loadState: $loadState, rootPath: $rootPath, currentPath: $currentPath, items: $items, visibleCount: $visibleCount, sort: $sort, canGoBack: $canGoBack, canGoForward: $canGoForward)';
}


}

/// @nodoc
abstract mixin class $GalleryUiStateCopyWith<$Res>  {
  factory $GalleryUiStateCopyWith(GalleryUiState value, $Res Function(GalleryUiState) _then) = _$GalleryUiStateCopyWithImpl;
@useResult
$Res call({
 GalleryLoadState loadState, String? rootPath, String? currentPath, List<GalleryItem> items, int visibleCount, GallerySort sort, bool canGoBack, bool canGoForward
});


$GalleryLoadStateCopyWith<$Res> get loadState;

}
/// @nodoc
class _$GalleryUiStateCopyWithImpl<$Res>
    implements $GalleryUiStateCopyWith<$Res> {
  _$GalleryUiStateCopyWithImpl(this._self, this._then);

  final GalleryUiState _self;
  final $Res Function(GalleryUiState) _then;

/// Create a copy of GalleryUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadState = null,Object? rootPath = freezed,Object? currentPath = freezed,Object? items = null,Object? visibleCount = null,Object? sort = null,Object? canGoBack = null,Object? canGoForward = null,}) {
  return _then(_self.copyWith(
loadState: null == loadState ? _self.loadState : loadState // ignore: cast_nullable_to_non_nullable
as GalleryLoadState,rootPath: freezed == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String?,currentPath: freezed == currentPath ? _self.currentPath : currentPath // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GalleryItem>,visibleCount: null == visibleCount ? _self.visibleCount : visibleCount // ignore: cast_nullable_to_non_nullable
as int,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as GallerySort,canGoBack: null == canGoBack ? _self.canGoBack : canGoBack // ignore: cast_nullable_to_non_nullable
as bool,canGoForward: null == canGoForward ? _self.canGoForward : canGoForward // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of GalleryUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GalleryLoadStateCopyWith<$Res> get loadState {
  
  return $GalleryLoadStateCopyWith<$Res>(_self.loadState, (value) {
    return _then(_self.copyWith(loadState: value));
  });
}
}


/// Adds pattern-matching-related methods to [GalleryUiState].
extension GalleryUiStatePatterns on GalleryUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GalleryUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GalleryUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GalleryUiState value)  $default,){
final _that = this;
switch (_that) {
case _GalleryUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GalleryUiState value)?  $default,){
final _that = this;
switch (_that) {
case _GalleryUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GalleryLoadState loadState,  String? rootPath,  String? currentPath,  List<GalleryItem> items,  int visibleCount,  GallerySort sort,  bool canGoBack,  bool canGoForward)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GalleryUiState() when $default != null:
return $default(_that.loadState,_that.rootPath,_that.currentPath,_that.items,_that.visibleCount,_that.sort,_that.canGoBack,_that.canGoForward);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GalleryLoadState loadState,  String? rootPath,  String? currentPath,  List<GalleryItem> items,  int visibleCount,  GallerySort sort,  bool canGoBack,  bool canGoForward)  $default,) {final _that = this;
switch (_that) {
case _GalleryUiState():
return $default(_that.loadState,_that.rootPath,_that.currentPath,_that.items,_that.visibleCount,_that.sort,_that.canGoBack,_that.canGoForward);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GalleryLoadState loadState,  String? rootPath,  String? currentPath,  List<GalleryItem> items,  int visibleCount,  GallerySort sort,  bool canGoBack,  bool canGoForward)?  $default,) {final _that = this;
switch (_that) {
case _GalleryUiState() when $default != null:
return $default(_that.loadState,_that.rootPath,_that.currentPath,_that.items,_that.visibleCount,_that.sort,_that.canGoBack,_that.canGoForward);case _:
  return null;

}
}

}

/// @nodoc


class _GalleryUiState extends GalleryUiState {
  const _GalleryUiState({this.loadState = const GalleryLoadState.initial(), this.rootPath, this.currentPath, final  List<GalleryItem> items = const <GalleryItem>[], this.visibleCount = 60, this.sort = GallerySort.nameAscending, this.canGoBack = false, this.canGoForward = false}): _items = items,super._();
  

@override@JsonKey() final  GalleryLoadState loadState;
@override final  String? rootPath;
@override final  String? currentPath;
 final  List<GalleryItem> _items;
@override@JsonKey() List<GalleryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int visibleCount;
@override@JsonKey() final  GallerySort sort;
@override@JsonKey() final  bool canGoBack;
@override@JsonKey() final  bool canGoForward;

/// Create a copy of GalleryUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GalleryUiStateCopyWith<_GalleryUiState> get copyWith => __$GalleryUiStateCopyWithImpl<_GalleryUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GalleryUiState&&(identical(other.loadState, loadState) || other.loadState == loadState)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.currentPath, currentPath) || other.currentPath == currentPath)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.visibleCount, visibleCount) || other.visibleCount == visibleCount)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.canGoBack, canGoBack) || other.canGoBack == canGoBack)&&(identical(other.canGoForward, canGoForward) || other.canGoForward == canGoForward));
}


@override
int get hashCode => Object.hash(runtimeType,loadState,rootPath,currentPath,const DeepCollectionEquality().hash(_items),visibleCount,sort,canGoBack,canGoForward);

@override
String toString() {
  return 'GalleryUiState(loadState: $loadState, rootPath: $rootPath, currentPath: $currentPath, items: $items, visibleCount: $visibleCount, sort: $sort, canGoBack: $canGoBack, canGoForward: $canGoForward)';
}


}

/// @nodoc
abstract mixin class _$GalleryUiStateCopyWith<$Res> implements $GalleryUiStateCopyWith<$Res> {
  factory _$GalleryUiStateCopyWith(_GalleryUiState value, $Res Function(_GalleryUiState) _then) = __$GalleryUiStateCopyWithImpl;
@override @useResult
$Res call({
 GalleryLoadState loadState, String? rootPath, String? currentPath, List<GalleryItem> items, int visibleCount, GallerySort sort, bool canGoBack, bool canGoForward
});


@override $GalleryLoadStateCopyWith<$Res> get loadState;

}
/// @nodoc
class __$GalleryUiStateCopyWithImpl<$Res>
    implements _$GalleryUiStateCopyWith<$Res> {
  __$GalleryUiStateCopyWithImpl(this._self, this._then);

  final _GalleryUiState _self;
  final $Res Function(_GalleryUiState) _then;

/// Create a copy of GalleryUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadState = null,Object? rootPath = freezed,Object? currentPath = freezed,Object? items = null,Object? visibleCount = null,Object? sort = null,Object? canGoBack = null,Object? canGoForward = null,}) {
  return _then(_GalleryUiState(
loadState: null == loadState ? _self.loadState : loadState // ignore: cast_nullable_to_non_nullable
as GalleryLoadState,rootPath: freezed == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String?,currentPath: freezed == currentPath ? _self.currentPath : currentPath // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GalleryItem>,visibleCount: null == visibleCount ? _self.visibleCount : visibleCount // ignore: cast_nullable_to_non_nullable
as int,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as GallerySort,canGoBack: null == canGoBack ? _self.canGoBack : canGoBack // ignore: cast_nullable_to_non_nullable
as bool,canGoForward: null == canGoForward ? _self.canGoForward : canGoForward // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of GalleryUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GalleryLoadStateCopyWith<$Res> get loadState {
  
  return $GalleryLoadStateCopyWith<$Res>(_self.loadState, (value) {
    return _then(_self.copyWith(loadState: value));
  });
}
}

// dart format on
