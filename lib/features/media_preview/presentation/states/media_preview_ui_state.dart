import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';

part 'media_preview_ui_state.freezed.dart';

@freezed
abstract class MediaPreviewUiState with _$MediaPreviewUiState {
  const MediaPreviewUiState._();

  const factory MediaPreviewUiState({
    @Default(<MediaItem>[]) List<MediaItem> items,
    @Default(0) int activeIndex,
    @Default(false) bool isPlaying,
    @Default(false) bool isVideoReady,
    @Default(false) bool isMuted,
    @Default(false) bool isLooping,
    @Default(true) bool controlsVisible,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(false) bool isRotationLocked,
    @Default(0) int lockedRotationQuarterTurns,
    @Default(<String, int>{}) Map<String, int> rotationByMediaPath,
  }) = _MediaPreviewUiState;

  MediaItem? get activeItem => items.isEmpty ? null : items[activeIndex];
  bool get hasPrevious => activeIndex > 0;
  bool get hasNext => activeIndex + 1 < items.length;

  int rotationFor(String? mediaPath) {
    if (isRotationLocked) return lockedRotationQuarterTurns;
    if (mediaPath == null) return 0;
    return rotationByMediaPath[mediaPath] ?? 0;
  }
}
