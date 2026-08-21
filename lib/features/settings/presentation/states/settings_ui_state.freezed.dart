// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsLoadState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsLoadState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsLoadState()';
}


}

/// @nodoc
class $SettingsLoadStateCopyWith<$Res>  {
$SettingsLoadStateCopyWith(SettingsLoadState _, $Res Function(SettingsLoadState) __);
}


/// Adds pattern-matching-related methods to [SettingsLoadState].
extension SettingsLoadStatePatterns on SettingsLoadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsLoading value)?  loading,TResult Function( SettingsRootRequired value)?  rootRequired,TResult Function( SettingsReady value)?  ready,TResult Function( SettingsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading(_that);case SettingsRootRequired() when rootRequired != null:
return rootRequired(_that);case SettingsReady() when ready != null:
return ready(_that);case SettingsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsLoading value)  loading,required TResult Function( SettingsRootRequired value)  rootRequired,required TResult Function( SettingsReady value)  ready,required TResult Function( SettingsError value)  error,}){
final _that = this;
switch (_that) {
case SettingsLoading():
return loading(_that);case SettingsRootRequired():
return rootRequired(_that);case SettingsReady():
return ready(_that);case SettingsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsLoading value)?  loading,TResult? Function( SettingsRootRequired value)?  rootRequired,TResult? Function( SettingsReady value)?  ready,TResult? Function( SettingsError value)?  error,}){
final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading(_that);case SettingsRootRequired() when rootRequired != null:
return rootRequired(_that);case SettingsReady() when ready != null:
return ready(_that);case SettingsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  rootRequired,TResult Function( String rootPath)?  ready,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading();case SettingsRootRequired() when rootRequired != null:
return rootRequired();case SettingsReady() when ready != null:
return ready(_that.rootPath);case SettingsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  rootRequired,required TResult Function( String rootPath)  ready,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SettingsLoading():
return loading();case SettingsRootRequired():
return rootRequired();case SettingsReady():
return ready(_that.rootPath);case SettingsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  rootRequired,TResult? Function( String rootPath)?  ready,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading();case SettingsRootRequired() when rootRequired != null:
return rootRequired();case SettingsReady() when ready != null:
return ready(_that.rootPath);case SettingsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SettingsLoading implements SettingsLoadState {
  const SettingsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsLoadState.loading()';
}


}




/// @nodoc


class SettingsRootRequired implements SettingsLoadState {
  const SettingsRootRequired();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsRootRequired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsLoadState.rootRequired()';
}


}




/// @nodoc


class SettingsReady implements SettingsLoadState {
  const SettingsReady(this.rootPath);
  

 final  String rootPath;

/// Create a copy of SettingsLoadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsReadyCopyWith<SettingsReady> get copyWith => _$SettingsReadyCopyWithImpl<SettingsReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsReady&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath));
}


@override
int get hashCode => Object.hash(runtimeType,rootPath);

@override
String toString() {
  return 'SettingsLoadState.ready(rootPath: $rootPath)';
}


}

/// @nodoc
abstract mixin class $SettingsReadyCopyWith<$Res> implements $SettingsLoadStateCopyWith<$Res> {
  factory $SettingsReadyCopyWith(SettingsReady value, $Res Function(SettingsReady) _then) = _$SettingsReadyCopyWithImpl;
@useResult
$Res call({
 String rootPath
});




}
/// @nodoc
class _$SettingsReadyCopyWithImpl<$Res>
    implements $SettingsReadyCopyWith<$Res> {
  _$SettingsReadyCopyWithImpl(this._self, this._then);

  final SettingsReady _self;
  final $Res Function(SettingsReady) _then;

/// Create a copy of SettingsLoadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rootPath = null,}) {
  return _then(SettingsReady(
null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SettingsError implements SettingsLoadState {
  const SettingsError(this.message);
  

 final  String message;

/// Create a copy of SettingsLoadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsErrorCopyWith<SettingsError> get copyWith => _$SettingsErrorCopyWithImpl<SettingsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SettingsLoadState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SettingsErrorCopyWith<$Res> implements $SettingsLoadStateCopyWith<$Res> {
  factory $SettingsErrorCopyWith(SettingsError value, $Res Function(SettingsError) _then) = _$SettingsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SettingsErrorCopyWithImpl<$Res>
    implements $SettingsErrorCopyWith<$Res> {
  _$SettingsErrorCopyWithImpl(this._self, this._then);

  final SettingsError _self;
  final $Res Function(SettingsError) _then;

/// Create a copy of SettingsLoadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SettingsError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SettingsUiState {

 SettingsLoadState get loadState; AppAppearanceMode get appearanceMode; AppColorTheme get colorTheme; bool get showItemNames; GalleryLayoutMode get galleryLayoutMode; double get galleryItemExtent; GallerySort get gallerySort; GalleryStyleLevel get galleryGridSpacing; GalleryStyleLevel get galleryCornerRadius;
/// Create a copy of SettingsUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsUiStateCopyWith<SettingsUiState> get copyWith => _$SettingsUiStateCopyWithImpl<SettingsUiState>(this as SettingsUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsUiState&&(identical(other.loadState, loadState) || other.loadState == loadState)&&(identical(other.appearanceMode, appearanceMode) || other.appearanceMode == appearanceMode)&&(identical(other.colorTheme, colorTheme) || other.colorTheme == colorTheme)&&(identical(other.showItemNames, showItemNames) || other.showItemNames == showItemNames)&&(identical(other.galleryLayoutMode, galleryLayoutMode) || other.galleryLayoutMode == galleryLayoutMode)&&(identical(other.galleryItemExtent, galleryItemExtent) || other.galleryItemExtent == galleryItemExtent)&&(identical(other.gallerySort, gallerySort) || other.gallerySort == gallerySort)&&(identical(other.galleryGridSpacing, galleryGridSpacing) || other.galleryGridSpacing == galleryGridSpacing)&&(identical(other.galleryCornerRadius, galleryCornerRadius) || other.galleryCornerRadius == galleryCornerRadius));
}


@override
int get hashCode => Object.hash(runtimeType,loadState,appearanceMode,colorTheme,showItemNames,galleryLayoutMode,galleryItemExtent,gallerySort,galleryGridSpacing,galleryCornerRadius);

@override
String toString() {
  return 'SettingsUiState(loadState: $loadState, appearanceMode: $appearanceMode, colorTheme: $colorTheme, showItemNames: $showItemNames, galleryLayoutMode: $galleryLayoutMode, galleryItemExtent: $galleryItemExtent, gallerySort: $gallerySort, galleryGridSpacing: $galleryGridSpacing, galleryCornerRadius: $galleryCornerRadius)';
}


}

/// @nodoc
abstract mixin class $SettingsUiStateCopyWith<$Res>  {
  factory $SettingsUiStateCopyWith(SettingsUiState value, $Res Function(SettingsUiState) _then) = _$SettingsUiStateCopyWithImpl;
@useResult
$Res call({
 SettingsLoadState loadState, AppAppearanceMode appearanceMode, AppColorTheme colorTheme, bool showItemNames, GalleryLayoutMode galleryLayoutMode, double galleryItemExtent, GallerySort gallerySort, GalleryStyleLevel galleryGridSpacing, GalleryStyleLevel galleryCornerRadius
});


$SettingsLoadStateCopyWith<$Res> get loadState;

}
/// @nodoc
class _$SettingsUiStateCopyWithImpl<$Res>
    implements $SettingsUiStateCopyWith<$Res> {
  _$SettingsUiStateCopyWithImpl(this._self, this._then);

  final SettingsUiState _self;
  final $Res Function(SettingsUiState) _then;

/// Create a copy of SettingsUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadState = null,Object? appearanceMode = null,Object? colorTheme = null,Object? showItemNames = null,Object? galleryLayoutMode = null,Object? galleryItemExtent = null,Object? gallerySort = null,Object? galleryGridSpacing = null,Object? galleryCornerRadius = null,}) {
  return _then(_self.copyWith(
loadState: null == loadState ? _self.loadState : loadState // ignore: cast_nullable_to_non_nullable
as SettingsLoadState,appearanceMode: null == appearanceMode ? _self.appearanceMode : appearanceMode // ignore: cast_nullable_to_non_nullable
as AppAppearanceMode,colorTheme: null == colorTheme ? _self.colorTheme : colorTheme // ignore: cast_nullable_to_non_nullable
as AppColorTheme,showItemNames: null == showItemNames ? _self.showItemNames : showItemNames // ignore: cast_nullable_to_non_nullable
as bool,galleryLayoutMode: null == galleryLayoutMode ? _self.galleryLayoutMode : galleryLayoutMode // ignore: cast_nullable_to_non_nullable
as GalleryLayoutMode,galleryItemExtent: null == galleryItemExtent ? _self.galleryItemExtent : galleryItemExtent // ignore: cast_nullable_to_non_nullable
as double,gallerySort: null == gallerySort ? _self.gallerySort : gallerySort // ignore: cast_nullable_to_non_nullable
as GallerySort,galleryGridSpacing: null == galleryGridSpacing ? _self.galleryGridSpacing : galleryGridSpacing // ignore: cast_nullable_to_non_nullable
as GalleryStyleLevel,galleryCornerRadius: null == galleryCornerRadius ? _self.galleryCornerRadius : galleryCornerRadius // ignore: cast_nullable_to_non_nullable
as GalleryStyleLevel,
  ));
}
/// Create a copy of SettingsUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsLoadStateCopyWith<$Res> get loadState {
  
  return $SettingsLoadStateCopyWith<$Res>(_self.loadState, (value) {
    return _then(_self.copyWith(loadState: value));
  });
}
}


/// Adds pattern-matching-related methods to [SettingsUiState].
extension SettingsUiStatePatterns on SettingsUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsUiState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsUiState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SettingsLoadState loadState,  AppAppearanceMode appearanceMode,  AppColorTheme colorTheme,  bool showItemNames,  GalleryLayoutMode galleryLayoutMode,  double galleryItemExtent,  GallerySort gallerySort,  GalleryStyleLevel galleryGridSpacing,  GalleryStyleLevel galleryCornerRadius)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsUiState() when $default != null:
return $default(_that.loadState,_that.appearanceMode,_that.colorTheme,_that.showItemNames,_that.galleryLayoutMode,_that.galleryItemExtent,_that.gallerySort,_that.galleryGridSpacing,_that.galleryCornerRadius);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SettingsLoadState loadState,  AppAppearanceMode appearanceMode,  AppColorTheme colorTheme,  bool showItemNames,  GalleryLayoutMode galleryLayoutMode,  double galleryItemExtent,  GallerySort gallerySort,  GalleryStyleLevel galleryGridSpacing,  GalleryStyleLevel galleryCornerRadius)  $default,) {final _that = this;
switch (_that) {
case _SettingsUiState():
return $default(_that.loadState,_that.appearanceMode,_that.colorTheme,_that.showItemNames,_that.galleryLayoutMode,_that.galleryItemExtent,_that.gallerySort,_that.galleryGridSpacing,_that.galleryCornerRadius);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SettingsLoadState loadState,  AppAppearanceMode appearanceMode,  AppColorTheme colorTheme,  bool showItemNames,  GalleryLayoutMode galleryLayoutMode,  double galleryItemExtent,  GallerySort gallerySort,  GalleryStyleLevel galleryGridSpacing,  GalleryStyleLevel galleryCornerRadius)?  $default,) {final _that = this;
switch (_that) {
case _SettingsUiState() when $default != null:
return $default(_that.loadState,_that.appearanceMode,_that.colorTheme,_that.showItemNames,_that.galleryLayoutMode,_that.galleryItemExtent,_that.gallerySort,_that.galleryGridSpacing,_that.galleryCornerRadius);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsUiState extends SettingsUiState {
  const _SettingsUiState({this.loadState = const SettingsLoadState.loading(), this.appearanceMode = AppAppearanceMode.system, this.colorTheme = AppColorTheme.indigo, this.showItemNames = true, this.galleryLayoutMode = GalleryLayoutMode.grid, this.galleryItemExtent = GalleryItemExtent.defaultValue, this.gallerySort = GallerySort.nameAscending, this.galleryGridSpacing = GalleryStyleLevel.standard, this.galleryCornerRadius = GalleryStyleLevel.standard}): super._();
  

@override@JsonKey() final  SettingsLoadState loadState;
@override@JsonKey() final  AppAppearanceMode appearanceMode;
@override@JsonKey() final  AppColorTheme colorTheme;
@override@JsonKey() final  bool showItemNames;
@override@JsonKey() final  GalleryLayoutMode galleryLayoutMode;
@override@JsonKey() final  double galleryItemExtent;
@override@JsonKey() final  GallerySort gallerySort;
@override@JsonKey() final  GalleryStyleLevel galleryGridSpacing;
@override@JsonKey() final  GalleryStyleLevel galleryCornerRadius;

/// Create a copy of SettingsUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsUiStateCopyWith<_SettingsUiState> get copyWith => __$SettingsUiStateCopyWithImpl<_SettingsUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsUiState&&(identical(other.loadState, loadState) || other.loadState == loadState)&&(identical(other.appearanceMode, appearanceMode) || other.appearanceMode == appearanceMode)&&(identical(other.colorTheme, colorTheme) || other.colorTheme == colorTheme)&&(identical(other.showItemNames, showItemNames) || other.showItemNames == showItemNames)&&(identical(other.galleryLayoutMode, galleryLayoutMode) || other.galleryLayoutMode == galleryLayoutMode)&&(identical(other.galleryItemExtent, galleryItemExtent) || other.galleryItemExtent == galleryItemExtent)&&(identical(other.gallerySort, gallerySort) || other.gallerySort == gallerySort)&&(identical(other.galleryGridSpacing, galleryGridSpacing) || other.galleryGridSpacing == galleryGridSpacing)&&(identical(other.galleryCornerRadius, galleryCornerRadius) || other.galleryCornerRadius == galleryCornerRadius));
}


@override
int get hashCode => Object.hash(runtimeType,loadState,appearanceMode,colorTheme,showItemNames,galleryLayoutMode,galleryItemExtent,gallerySort,galleryGridSpacing,galleryCornerRadius);

@override
String toString() {
  return 'SettingsUiState(loadState: $loadState, appearanceMode: $appearanceMode, colorTheme: $colorTheme, showItemNames: $showItemNames, galleryLayoutMode: $galleryLayoutMode, galleryItemExtent: $galleryItemExtent, gallerySort: $gallerySort, galleryGridSpacing: $galleryGridSpacing, galleryCornerRadius: $galleryCornerRadius)';
}


}

/// @nodoc
abstract mixin class _$SettingsUiStateCopyWith<$Res> implements $SettingsUiStateCopyWith<$Res> {
  factory _$SettingsUiStateCopyWith(_SettingsUiState value, $Res Function(_SettingsUiState) _then) = __$SettingsUiStateCopyWithImpl;
@override @useResult
$Res call({
 SettingsLoadState loadState, AppAppearanceMode appearanceMode, AppColorTheme colorTheme, bool showItemNames, GalleryLayoutMode galleryLayoutMode, double galleryItemExtent, GallerySort gallerySort, GalleryStyleLevel galleryGridSpacing, GalleryStyleLevel galleryCornerRadius
});


@override $SettingsLoadStateCopyWith<$Res> get loadState;

}
/// @nodoc
class __$SettingsUiStateCopyWithImpl<$Res>
    implements _$SettingsUiStateCopyWith<$Res> {
  __$SettingsUiStateCopyWithImpl(this._self, this._then);

  final _SettingsUiState _self;
  final $Res Function(_SettingsUiState) _then;

/// Create a copy of SettingsUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadState = null,Object? appearanceMode = null,Object? colorTheme = null,Object? showItemNames = null,Object? galleryLayoutMode = null,Object? galleryItemExtent = null,Object? gallerySort = null,Object? galleryGridSpacing = null,Object? galleryCornerRadius = null,}) {
  return _then(_SettingsUiState(
loadState: null == loadState ? _self.loadState : loadState // ignore: cast_nullable_to_non_nullable
as SettingsLoadState,appearanceMode: null == appearanceMode ? _self.appearanceMode : appearanceMode // ignore: cast_nullable_to_non_nullable
as AppAppearanceMode,colorTheme: null == colorTheme ? _self.colorTheme : colorTheme // ignore: cast_nullable_to_non_nullable
as AppColorTheme,showItemNames: null == showItemNames ? _self.showItemNames : showItemNames // ignore: cast_nullable_to_non_nullable
as bool,galleryLayoutMode: null == galleryLayoutMode ? _self.galleryLayoutMode : galleryLayoutMode // ignore: cast_nullable_to_non_nullable
as GalleryLayoutMode,galleryItemExtent: null == galleryItemExtent ? _self.galleryItemExtent : galleryItemExtent // ignore: cast_nullable_to_non_nullable
as double,gallerySort: null == gallerySort ? _self.gallerySort : gallerySort // ignore: cast_nullable_to_non_nullable
as GallerySort,galleryGridSpacing: null == galleryGridSpacing ? _self.galleryGridSpacing : galleryGridSpacing // ignore: cast_nullable_to_non_nullable
as GalleryStyleLevel,galleryCornerRadius: null == galleryCornerRadius ? _self.galleryCornerRadius : galleryCornerRadius // ignore: cast_nullable_to_non_nullable
as GalleryStyleLevel,
  ));
}

/// Create a copy of SettingsUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsLoadStateCopyWith<$Res> get loadState {
  
  return $SettingsLoadStateCopyWith<$Res>(_self.loadState, (value) {
    return _then(_self.copyWith(loadState: value));
  });
}
}

// dart format on
