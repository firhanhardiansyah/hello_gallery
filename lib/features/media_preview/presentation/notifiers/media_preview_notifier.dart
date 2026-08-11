import 'dart:async';

import 'package:flutter/foundation.dart';
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
  final _playerPool = <String, _VideoPlayerSlot>{};
  _VideoPlayerSlot? _activeSlot;
  int _openGeneration = 0;

  VideoController? get videoController => _videoController;

  @override
  MediaPreviewUiState build() {
    ref.onDispose(() {
      _openGeneration++;
      unawaited(_disposeAllPlayers());
    });
    return const MediaPreviewUiState();
  }

  Future<void> configure(List<MediaItem> items, int initialIndex) async {
    await _disposeAllPlayers();
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
      await _disposeAllPlayers();
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
    if (sourceChanged) {
      await _openActive(forceReload: true);
    } else {
      unawaited(_syncPreloadWindow(_openGeneration));
    }
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
    if (state.activeItem?.isVideo != true || _player == null) return;
    final position = state.position;
    final wasPlaying = state.isPlaying;
    final wasMuted = state.isMuted;
    await _disposeAllPlayers();
    await _openActive(
      initialPosition: position,
      playWhenReady: wasPlaying,
      muted: wasMuted,
    );
  }

  Future<void> _openActive({
    Duration initialPosition = Duration.zero,
    bool playWhenReady = true,
    bool muted = false,
    bool forceReload = false,
  }) async {
    final generation = ++_openGeneration;
    final previousSlot = _activeSlot;
    final item = state.activeItem;
    final cachedSlot = item == null || forceReload
        ? null
        : _playerPool[item.path];
    final warmSlot =
        cachedSlot != null &&
            cachedSlot.item == item &&
            cachedSlot.prepared &&
            !cachedSlot.disposed
        ? cachedSlot
        : null;
    final warmPlayerState = warmSlot?.player.state;
    _activeSlot = warmSlot;
    _player = warmSlot?.player;
    _videoController = warmSlot?.controller;
    state = state.copyWith(
      isPlaying: false,
      isVideoReady:
          warmPlayerState != null &&
          ((warmPlayerState.width ?? 0) > 0 ||
              warmPlayerState.position > Duration.zero),
      isMuted: false,
      position: warmPlayerState?.position ?? Duration.zero,
      duration: warmPlayerState?.duration ?? Duration.zero,
    );
    await _cancelActiveSubscriptions();
    await previousSlot?.player.pause();
    if (generation != _openGeneration) return;
    if (item == null || !item.isVideo) {
      if (previousSlot != null && !previousSlot.disposed) {
        unawaited(_resetSlotPosition(previousSlot));
      }
      unawaited(_syncPreloadWindow(generation));
      return;
    }
    if (forceReload) {
      await _removeSlot(item.path);
    }
    final slot = await _obtainSlot(item);
    if (generation != _openGeneration || slot == null) return;
    final player = slot.player;
    _activeSlot = slot;
    _player = player;
    _videoController = slot.controller;
    final playerState = player.state;
    state = state.copyWith(
      duration: playerState.duration,
      position: playerState.position,
      isVideoReady:
          (playerState.width ?? 0) > 0 || playerState.position > Duration.zero,
    );
    _subscriptions.addAll([
      player.stream.playing.listen((playing) {
        if (generation != _openGeneration) return;
        state = state.copyWith(isPlaying: playing);
      }),
      player.stream.position.listen((position) {
        if (generation != _openGeneration) return;
        state = state.copyWith(
          position: position,
          isVideoReady: state.isVideoReady || position > Duration.zero,
        );
      }),
      player.stream.duration.listen((duration) {
        if (generation != _openGeneration) return;
        state = state.copyWith(duration: duration);
      }),
      player.stream.width.listen((width) {
        if (generation != _openGeneration || (width ?? 0) <= 0) return;
        state = state.copyWith(isVideoReady: true);
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
    final playlistMode = state.isLooping
        ? PlaylistMode.single
        : PlaylistMode.none;
    if (player.state.playlistMode != playlistMode) {
      await player.setPlaylistMode(playlistMode);
    }
    if (initialPosition > Duration.zero) {
      await player.seek(initialPosition);
    }
    if (muted) {
      if (player.state.volume != 0) await player.setVolume(0);
      state = state.copyWith(isMuted: true);
    } else if (player.state.volume != 100) {
      await player.setVolume(100);
    }
    if (playWhenReady) await player.play();
    if (generation != _openGeneration) return;
    if (previousSlot != null &&
        !previousSlot.disposed &&
        !identical(previousSlot, slot)) {
      unawaited(_resetSlotPosition(previousSlot));
    }
    unawaited(_syncPreloadWindow(generation));
  }

  Future<void> _resetSlotPosition(_VideoPlayerSlot slot) async {
    try {
      if (!slot.disposed) await slot.player.seek(Duration.zero);
    } on Object catch (error) {
      if (!slot.disposed) {
        debugPrint('Could not reset video ${slot.item.path}: $error');
      }
    }
  }

  Future<_VideoPlayerSlot?> _obtainSlot(MediaItem item) async {
    var slot = _playerPool[item.path];
    if (slot != null && slot.item != item) {
      await _removeSlot(item.path);
      slot = null;
    }
    if (slot == null) {
      final player = Player();
      slot = _VideoPlayerSlot(item: item, player: player);
      _playerPool[item.path] = slot;
      slot.preparation = _prepareSlot(slot);
    }
    final prepared = await slot.preparation;
    if (!prepared ||
        slot.disposed ||
        !identical(_playerPool[item.path], slot)) {
      return null;
    }
    return slot;
  }

  Future<bool> _prepareSlot(_VideoPlayerSlot slot) async {
    try {
      final player = slot.player;
      await ref.read(mediaKitVideoColorConfiguratorProvider).configure(player);
      if (slot.disposed) return false;
      slot.controller = VideoController(player);
      await player.open(Media(slot.item.path), play: false);
      if (slot.disposed) return false;
      // Reapply after libmpv has read the source color metadata. Some target
      // properties are resolved against the active video's transfer function.
      await ref.read(mediaKitVideoColorConfiguratorProvider).configure(player);
      slot.prepared = true;
      return !slot.disposed;
    } on Object catch (error) {
      if (!slot.disposed) {
        debugPrint('Could not preload video ${slot.item.path}: $error');
        await _removeSlot(slot.item.path, expected: slot);
      }
      return false;
    }
  }

  Future<void> _syncPreloadWindow(int generation) async {
    if (generation != _openGeneration || state.items.isEmpty) return;
    final activeIndex = state.activeIndex;
    final candidates = <MediaItem>[];
    for (final index in [activeIndex - 1, activeIndex, activeIndex + 1]) {
      if (index >= 0 && index < state.items.length) {
        final item = state.items[index];
        if (item.isVideo) candidates.add(item);
      }
    }
    final retainedPaths = candidates.map((item) => item.path).toSet();
    final obsoleteSlots = _playerPool.entries
        .where((entry) => !retainedPaths.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    for (final slot in obsoleteSlots) {
      if (generation != _openGeneration) return;
      await _removeSlot(slot.item.path, expected: slot);
    }
    if (generation != _openGeneration) return;
    await Future.wait(
      candidates
          .where((item) => item.path != state.activeItem?.path)
          .map(_obtainSlot),
    );
  }

  Future<void> _removeSlot(
    String mediaPath, {
    _VideoPlayerSlot? expected,
  }) async {
    final slot = _playerPool[mediaPath];
    if (slot == null || (expected != null && !identical(slot, expected))) {
      return;
    }
    _playerPool.remove(mediaPath);
    if (identical(_activeSlot, slot)) {
      _activeSlot = null;
      _player = null;
      _videoController = null;
    }
    await slot.dispose();
  }

  Future<void> _cancelActiveSubscriptions() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  Future<void> _disposeAllPlayers() async {
    await _cancelActiveSubscriptions();
    final slots = _playerPool.values.toSet().toList();
    _playerPool.clear();
    _activeSlot = null;
    _player = null;
    _videoController = null;
    for (final slot in slots) {
      await slot.dispose();
    }
  }
}

final class _VideoPlayerSlot {
  _VideoPlayerSlot({required this.item, required this.player});

  final MediaItem item;
  final Player player;
  late final Future<bool> preparation;
  late final VideoController controller;
  bool prepared = false;
  bool disposed = false;

  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    await player.dispose();
  }
}
