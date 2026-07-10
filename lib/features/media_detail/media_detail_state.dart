import '../../shared/models/gallery_item.dart';

class MediaDetailState {
  const MediaDetailState({
    this.items = const [],
    this.activeIndex = 0,
    this.isPlaying = false,
    this.isMuted = false,
    this.controlsVisible = true,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final List<MediaItem> items;
  final int activeIndex;
  final bool isPlaying;
  final bool isMuted;
  final bool controlsVisible;
  final Duration position;
  final Duration duration;

  MediaItem? get activeItem => items.isEmpty ? null : items[activeIndex];
  bool get hasPrevious => activeIndex > 0;
  bool get hasNext => activeIndex + 1 < items.length;

  MediaDetailState copyWith({
    List<MediaItem>? items,
    int? activeIndex,
    bool? isPlaying,
    bool? isMuted,
    bool? controlsVisible,
    Duration? position,
    Duration? duration,
  }) => MediaDetailState(
    items: items ?? this.items,
    activeIndex: activeIndex ?? this.activeIndex,
    isPlaying: isPlaying ?? this.isPlaying,
    isMuted: isMuted ?? this.isMuted,
    controlsVisible: controlsVisible ?? this.controlsVisible,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );
}
