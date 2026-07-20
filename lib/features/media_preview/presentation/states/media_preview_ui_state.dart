import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';

class MediaPreviewUiState {
  const MediaPreviewUiState({
    this.items = const [],
    this.activeIndex = 0,
    this.isPlaying = false,
    this.isVideoReady = false,
    this.isMuted = false,
    this.controlsVisible = true,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final List<MediaItem> items;
  final int activeIndex;
  final bool isPlaying;
  final bool isVideoReady;
  final bool isMuted;
  final bool controlsVisible;
  final Duration position;
  final Duration duration;

  MediaItem? get activeItem => items.isEmpty ? null : items[activeIndex];
  bool get hasPrevious => activeIndex > 0;
  bool get hasNext => activeIndex + 1 < items.length;

  MediaPreviewUiState copyWith({
    List<MediaItem>? items,
    int? activeIndex,
    bool? isPlaying,
    bool? isVideoReady,
    bool? isMuted,
    bool? controlsVisible,
    Duration? position,
    Duration? duration,
  }) => MediaPreviewUiState(
    items: items ?? this.items,
    activeIndex: activeIndex ?? this.activeIndex,
    isPlaying: isPlaying ?? this.isPlaying,
    isVideoReady: isVideoReady ?? this.isVideoReady,
    isMuted: isMuted ?? this.isMuted,
    controlsVisible: controlsVisible ?? this.controlsVisible,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );
}
