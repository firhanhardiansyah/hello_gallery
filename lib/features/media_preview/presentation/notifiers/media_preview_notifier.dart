import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;

import '../../application/providers/media_preview_dependencies.dart';
import '../states/media_preview_ui_state.dart';

final mediaPreviewNotifierProvider =
    NotifierProvider.autoDispose<MediaPreviewNotifier, MediaPreviewUiState>(
      MediaPreviewNotifier.new,
    );

class MediaPreviewNotifier extends Notifier<MediaPreviewUiState> {
  Player? _player;
  VideoController? _videoController;
  final _subscriptions = <StreamSubscription<Object?>>[];
  int _openGeneration = 0;

  VideoController? get videoController => _videoController;

  @override
  MediaPreviewUiState build() {
    ref.onDispose(() {
      _openGeneration++;
      unawaited(_disposePlayer());
    });
    return const MediaPreviewUiState();
  }

  Future<void> configure(List<MediaItem> items, int initialIndex) async {
    state = MediaPreviewUiState(
      items: items,
      activeIndex: initialIndex.clamp(0, items.length - 1),
    );
    await _openActive();
  }

  Future<void> next() => _moveBy(1);

  Future<void> previous() => _moveBy(-1);

  Future<void> nextVideo() async {
    final activePath = state.activeItem?.path;
    if (activePath == null) return;
    final currentIndex = state.items.indexWhere(
      (item) => path.equals(item.path, activePath),
    );
    if (currentIndex < 0) return;
    final relativeIndex = state.items
        .skip(currentIndex + 1)
        .toList()
        .indexWhere((item) => item.isVideo);
    if (relativeIndex < 0) return;
    state = state.copyWith(activeIndex: currentIndex + 1 + relativeIndex);
    await _openActive();
  }

  Future<void> _moveBy(int offset) async {
    final activePath = state.activeItem?.path;
    if (activePath == null) return;
    final currentIndex = state.items.indexWhere(
      (item) => path.equals(item.path, activePath),
    );
    final targetIndex = currentIndex + offset;
    if (currentIndex < 0 ||
        targetIndex < 0 ||
        targetIndex >= state.items.length) {
      return;
    }
    state = state.copyWith(activeIndex: targetIndex);
    await _openActive();
  }

  Future<void> select(int index) async {
    if (index == state.activeIndex) return;
    state = state.copyWith(activeIndex: index);
    await _openActive();
  }

  Future<void> openMedia(MediaItem item) async {
    final existingIndex = state.items.indexWhere(
      (entry) => path.equals(entry.path, item.path),
    );
    if (existingIndex >= 0) {
      await select(existingIndex);
      return;
    }
    state = state.copyWith(
      items: [...state.items, item],
      activeIndex: state.items.length,
    );
    await _openActive();
  }

  Future<bool> reconcile(List<MediaItem> items) async {
    final previousItem = state.activeItem;
    final previousIndex = state.activeIndex;
    if (items.isEmpty) {
      state = const MediaPreviewUiState();
      await _disposePlayer();
      return false;
    }

    final matchingIndex = previousItem == null
        ? -1
        : items.indexWhere((item) => path.equals(item.path, previousItem.path));
    final nextIndex = matchingIndex >= 0
        ? matchingIndex
        : previousIndex.clamp(0, items.length - 1);
    final nextItem = items[nextIndex];
    final sourceChanged =
        previousItem == null ||
        !path.equals(previousItem.path, nextItem.path) ||
        previousItem.modifiedAt != nextItem.modifiedAt ||
        previousItem.sizeBytes != nextItem.sizeBytes;

    state = state.copyWith(items: items, activeIndex: nextIndex);
    if (sourceChanged) await _openActive();
    return true;
  }

  Future<void> togglePlay() async => _player?.playOrPause();

  Future<void> toggleMute() async {
    final player = _player;
    if (player == null) return;
    await player.setVolume(state.isMuted ? 100 : 0);
    state = state.copyWith(isMuted: !state.isMuted);
  }

  Future<void> toggleLoop() async {
    final isLooping = !state.isLooping;
    await _player?.setPlaylistMode(
      isLooping ? PlaylistMode.single : PlaylistMode.none,
    );
    state = state.copyWith(isLooping: isLooping);
  }

  void rotateActiveMedia() {
    final mediaPath = state.activeItem?.path;
    if (mediaPath == null) return;
    if (state.isRotationLocked) {
      state = state.copyWith(
        lockedRotationQuarterTurns: (state.lockedRotationQuarterTurns + 1) % 4,
      );
      return;
    }
    state = state.copyWith(
      rotationByMediaPath: {
        ...state.rotationByMediaPath,
        mediaPath: ((state.rotationByMediaPath[mediaPath] ?? 0) + 1) % 4,
      },
    );
  }

  void toggleRotationLock() {
    final mediaPath = state.activeItem?.path;
    if (mediaPath == null) return;
    if (!state.isRotationLocked) {
      state = state.copyWith(
        isRotationLocked: true,
        lockedRotationQuarterTurns: state.rotationFor(mediaPath),
      );
      return;
    }
    state = state.copyWith(
      isRotationLocked: false,
      rotationByMediaPath: {
        ...state.rotationByMediaPath,
        mediaPath: state.lockedRotationQuarterTurns,
      },
    );
  }

  void resetRotation() {
    state = state.copyWith(
      isRotationLocked: false,
      lockedRotationQuarterTurns: 0,
      rotationByMediaPath: const {},
    );
  }

  Future<void> seekBy(Duration delta) async {
    final player = _player;
    if (player == null) return;
    final target = state.position + delta;
    await player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> seek(Duration position) async => _player?.seek(position);

  Future<void> applyPlaybackColorConfig() async {
    final player = _player;
    if (player == null) return;
    await ref.read(mediaKitVideoColorConfiguratorProvider).configure(player);
  }

  Future<void> _openActive() async {
    final generation = ++_openGeneration;
    state = state.copyWith(
      isPlaying: false,
      isVideoReady: false,
      isMuted: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
    await _disposePlayer();
    if (generation != _openGeneration) return;
    final item = state.activeItem;
    if (item == null || !item.isVideo) return;
    final player = Player();
    _player = player;
    _videoController = VideoController(player);
    // Notify the UI immediately that a new native video surface is available.
    state = state.copyWith();
    await ref.read(mediaKitVideoColorConfiguratorProvider).configure(player);
    if (generation != _openGeneration) return;
    _subscriptions.addAll([
      player.stream.playing.listen((playing) {
        state = state.copyWith(isPlaying: playing);
      }),
      player.stream.position.listen((position) {
        state = state.copyWith(
          position: position,
          isVideoReady: state.isVideoReady || position > Duration.zero,
        );
      }),
      player.stream.duration.listen((duration) {
        state = state.copyWith(duration: duration);
      }),
      player.stream.completed.listen((completed) {
        if (!completed || generation != _openGeneration) return;
        if (state.isLooping) return;
        final activeItem = state.activeItem;
        if (activeItem == null || !path.equals(activeItem.path, item.path)) {
          return;
        }
        unawaited(nextVideo());
      }),
    ]);
    await player.open(Media(item.path), play: false);
    if (generation != _openGeneration) return;
    await player.setPlaylistMode(
      state.isLooping ? PlaylistMode.single : PlaylistMode.none,
    );
    await player.play();
  }

  Future<void> _disposePlayer() async {
    final subscriptions = [..._subscriptions];
    final player = _player;
    _subscriptions.clear();
    _player = null;
    _videoController = null;
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await player?.dispose();
  }
}
