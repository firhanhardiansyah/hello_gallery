// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_preview_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaPreviewUiState {

 List<MediaItem> get items; int get activeIndex; bool get isPlaying; bool get isVideoReady; bool get isMuted; bool get isLooping; bool get controlsVisible; Duration get position; Duration get duration; bool get isRotationLocked; int get lockedRotationQuarterTurns; Map<String, int> get rotationByMediaPath;
/// Create a copy of MediaPreviewUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaPreviewUiStateCopyWith<MediaPreviewUiState> get copyWith => _$MediaPreviewUiStateCopyWithImpl<MediaPreviewUiState>(this as MediaPreviewUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaPreviewUiState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.activeIndex, activeIndex) || other.activeIndex == activeIndex)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isVideoReady, isVideoReady) || other.isVideoReady == isVideoReady)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isLooping, isLooping) || other.isLooping == isLooping)&&(identical(other.controlsVisible, controlsVisible) || other.controlsVisible == controlsVisible)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.isRotationLocked, isRotationLocked) || other.isRotationLocked == isRotationLocked)&&(identical(other.lockedRotationQuarterTurns, lockedRotationQuarterTurns) || other.lockedRotationQuarterTurns == lockedRotationQuarterTurns)&&const DeepCollectionEquality().equals(other.rotationByMediaPath, rotationByMediaPath));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),activeIndex,isPlaying,isVideoReady,isMuted,isLooping,controlsVisible,position,duration,isRotationLocked,lockedRotationQuarterTurns,const DeepCollectionEquality().hash(rotationByMediaPath));

@override
String toString() {
  return 'MediaPreviewUiState(items: $items, activeIndex: $activeIndex, isPlaying: $isPlaying, isVideoReady: $isVideoReady, isMuted: $isMuted, isLooping: $isLooping, controlsVisible: $controlsVisible, position: $position, duration: $duration, isRotationLocked: $isRotationLocked, lockedRotationQuarterTurns: $lockedRotationQuarterTurns, rotationByMediaPath: $rotationByMediaPath)';
}


}

/// @nodoc
abstract mixin class $MediaPreviewUiStateCopyWith<$Res>  {
  factory $MediaPreviewUiStateCopyWith(MediaPreviewUiState value, $Res Function(MediaPreviewUiState) _then) = _$MediaPreviewUiStateCopyWithImpl;
@useResult
$Res call({
 List<MediaItem> items, int activeIndex, bool isPlaying, bool isVideoReady, bool isMuted, bool isLooping, bool controlsVisible, Duration position, Duration duration, bool isRotationLocked, int lockedRotationQuarterTurns, Map<String, int> rotationByMediaPath
});




}
/// @nodoc
class _$MediaPreviewUiStateCopyWithImpl<$Res>
    implements $MediaPreviewUiStateCopyWith<$Res> {
  _$MediaPreviewUiStateCopyWithImpl(this._self, this._then);

  final MediaPreviewUiState _self;
  final $Res Function(MediaPreviewUiState) _then;

/// Create a copy of MediaPreviewUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? activeIndex = null,Object? isPlaying = null,Object? isVideoReady = null,Object? isMuted = null,Object? isLooping = null,Object? controlsVisible = null,Object? position = null,Object? duration = null,Object? isRotationLocked = null,Object? lockedRotationQuarterTurns = null,Object? rotationByMediaPath = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,activeIndex: null == activeIndex ? _self.activeIndex : activeIndex // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isVideoReady: null == isVideoReady ? _self.isVideoReady : isVideoReady // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isLooping: null == isLooping ? _self.isLooping : isLooping // ignore: cast_nullable_to_non_nullable
as bool,controlsVisible: null == controlsVisible ? _self.controlsVisible : controlsVisible // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,isRotationLocked: null == isRotationLocked ? _self.isRotationLocked : isRotationLocked // ignore: cast_nullable_to_non_nullable
as bool,lockedRotationQuarterTurns: null == lockedRotationQuarterTurns ? _self.lockedRotationQuarterTurns : lockedRotationQuarterTurns // ignore: cast_nullable_to_non_nullable
as int,rotationByMediaPath: null == rotationByMediaPath ? _self.rotationByMediaPath : rotationByMediaPath // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaPreviewUiState].
extension MediaPreviewUiStatePatterns on MediaPreviewUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaPreviewUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaPreviewUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaPreviewUiState value)  $default,){
final _that = this;
switch (_that) {
case _MediaPreviewUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaPreviewUiState value)?  $default,){
final _that = this;
switch (_that) {
case _MediaPreviewUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MediaItem> items,  int activeIndex,  bool isPlaying,  bool isVideoReady,  bool isMuted,  bool isLooping,  bool controlsVisible,  Duration position,  Duration duration,  bool isRotationLocked,  int lockedRotationQuarterTurns,  Map<String, int> rotationByMediaPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaPreviewUiState() when $default != null:
return $default(_that.items,_that.activeIndex,_that.isPlaying,_that.isVideoReady,_that.isMuted,_that.isLooping,_that.controlsVisible,_that.position,_that.duration,_that.isRotationLocked,_that.lockedRotationQuarterTurns,_that.rotationByMediaPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MediaItem> items,  int activeIndex,  bool isPlaying,  bool isVideoReady,  bool isMuted,  bool isLooping,  bool controlsVisible,  Duration position,  Duration duration,  bool isRotationLocked,  int lockedRotationQuarterTurns,  Map<String, int> rotationByMediaPath)  $default,) {final _that = this;
switch (_that) {
case _MediaPreviewUiState():
return $default(_that.items,_that.activeIndex,_that.isPlaying,_that.isVideoReady,_that.isMuted,_that.isLooping,_that.controlsVisible,_that.position,_that.duration,_that.isRotationLocked,_that.lockedRotationQuarterTurns,_that.rotationByMediaPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MediaItem> items,  int activeIndex,  bool isPlaying,  bool isVideoReady,  bool isMuted,  bool isLooping,  bool controlsVisible,  Duration position,  Duration duration,  bool isRotationLocked,  int lockedRotationQuarterTurns,  Map<String, int> rotationByMediaPath)?  $default,) {final _that = this;
switch (_that) {
case _MediaPreviewUiState() when $default != null:
return $default(_that.items,_that.activeIndex,_that.isPlaying,_that.isVideoReady,_that.isMuted,_that.isLooping,_that.controlsVisible,_that.position,_that.duration,_that.isRotationLocked,_that.lockedRotationQuarterTurns,_that.rotationByMediaPath);case _:
  return null;

}
}

}

/// @nodoc


class _MediaPreviewUiState extends MediaPreviewUiState {
  const _MediaPreviewUiState({final  List<MediaItem> items = const <MediaItem>[], this.activeIndex = 0, this.isPlaying = false, this.isVideoReady = false, this.isMuted = false, this.isLooping = false, this.controlsVisible = true, this.position = Duration.zero, this.duration = Duration.zero, this.isRotationLocked = false, this.lockedRotationQuarterTurns = 0, final  Map<String, int> rotationByMediaPath = const <String, int>{}}): _items = items,_rotationByMediaPath = rotationByMediaPath,super._();
  

 final  List<MediaItem> _items;
@override@JsonKey() List<MediaItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int activeIndex;
@override@JsonKey() final  bool isPlaying;
@override@JsonKey() final  bool isVideoReady;
@override@JsonKey() final  bool isMuted;
@override@JsonKey() final  bool isLooping;
@override@JsonKey() final  bool controlsVisible;
@override@JsonKey() final  Duration position;
@override@JsonKey() final  Duration duration;
@override@JsonKey() final  bool isRotationLocked;
@override@JsonKey() final  int lockedRotationQuarterTurns;
 final  Map<String, int> _rotationByMediaPath;
@override@JsonKey() Map<String, int> get rotationByMediaPath {
  if (_rotationByMediaPath is EqualUnmodifiableMapView) return _rotationByMediaPath;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rotationByMediaPath);
}


/// Create a copy of MediaPreviewUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaPreviewUiStateCopyWith<_MediaPreviewUiState> get copyWith => __$MediaPreviewUiStateCopyWithImpl<_MediaPreviewUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaPreviewUiState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.activeIndex, activeIndex) || other.activeIndex == activeIndex)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.isVideoReady, isVideoReady) || other.isVideoReady == isVideoReady)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isLooping, isLooping) || other.isLooping == isLooping)&&(identical(other.controlsVisible, controlsVisible) || other.controlsVisible == controlsVisible)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.isRotationLocked, isRotationLocked) || other.isRotationLocked == isRotationLocked)&&(identical(other.lockedRotationQuarterTurns, lockedRotationQuarterTurns) || other.lockedRotationQuarterTurns == lockedRotationQuarterTurns)&&const DeepCollectionEquality().equals(other._rotationByMediaPath, _rotationByMediaPath));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),activeIndex,isPlaying,isVideoReady,isMuted,isLooping,controlsVisible,position,duration,isRotationLocked,lockedRotationQuarterTurns,const DeepCollectionEquality().hash(_rotationByMediaPath));

@override
String toString() {
  return 'MediaPreviewUiState(items: $items, activeIndex: $activeIndex, isPlaying: $isPlaying, isVideoReady: $isVideoReady, isMuted: $isMuted, isLooping: $isLooping, controlsVisible: $controlsVisible, position: $position, duration: $duration, isRotationLocked: $isRotationLocked, lockedRotationQuarterTurns: $lockedRotationQuarterTurns, rotationByMediaPath: $rotationByMediaPath)';
}


}

/// @nodoc
abstract mixin class _$MediaPreviewUiStateCopyWith<$Res> implements $MediaPreviewUiStateCopyWith<$Res> {
  factory _$MediaPreviewUiStateCopyWith(_MediaPreviewUiState value, $Res Function(_MediaPreviewUiState) _then) = __$MediaPreviewUiStateCopyWithImpl;
@override @useResult
$Res call({
 List<MediaItem> items, int activeIndex, bool isPlaying, bool isVideoReady, bool isMuted, bool isLooping, bool controlsVisible, Duration position, Duration duration, bool isRotationLocked, int lockedRotationQuarterTurns, Map<String, int> rotationByMediaPath
});




}
/// @nodoc
class __$MediaPreviewUiStateCopyWithImpl<$Res>
    implements _$MediaPreviewUiStateCopyWith<$Res> {
  __$MediaPreviewUiStateCopyWithImpl(this._self, this._then);

  final _MediaPreviewUiState _self;
  final $Res Function(_MediaPreviewUiState) _then;

/// Create a copy of MediaPreviewUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? activeIndex = null,Object? isPlaying = null,Object? isVideoReady = null,Object? isMuted = null,Object? isLooping = null,Object? controlsVisible = null,Object? position = null,Object? duration = null,Object? isRotationLocked = null,Object? lockedRotationQuarterTurns = null,Object? rotationByMediaPath = null,}) {
  return _then(_MediaPreviewUiState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,activeIndex: null == activeIndex ? _self.activeIndex : activeIndex // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isVideoReady: null == isVideoReady ? _self.isVideoReady : isVideoReady // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isLooping: null == isLooping ? _self.isLooping : isLooping // ignore: cast_nullable_to_non_nullable
as bool,controlsVisible: null == controlsVisible ? _self.controlsVisible : controlsVisible // ignore: cast_nullable_to_non_nullable
as bool,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,isRotationLocked: null == isRotationLocked ? _self.isRotationLocked : isRotationLocked // ignore: cast_nullable_to_non_nullable
as bool,lockedRotationQuarterTurns: null == lockedRotationQuarterTurns ? _self.lockedRotationQuarterTurns : lockedRotationQuarterTurns // ignore: cast_nullable_to_non_nullable
as int,rotationByMediaPath: null == rotationByMediaPath ? _self._rotationByMediaPath : rotationByMediaPath // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
