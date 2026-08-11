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
  static const _activeFirstFrameTimeout = Duration(seconds: 2);
  static const _playbackStabilizationDelay = Duration(milliseconds: 800);
  static const _readinessPositionFallback = Duration(milliseconds: 300);
  static const _positionUiUpdateInterval = Duration(milliseconds: 200);

  Player? _player;
  VideoController? _videoController;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _playerPool = <String, _VideoPlayerSlot>{};
  _VideoPlayerSlot? _activeSlot;
  Timer? _preloadTimer;
  int _preferredPreloadOffset = 1;
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
    _preferredPreloadOffset = 1;
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
    _preferredPreloadOffset = offset.isNegative ? -1 : 1;
    state = state.copyWith(activeIndex: targetIndex);
    await _openActive();
  }

  Future<void> select(int index) async {
    if (index == state.activeIndex) return;
    _preferredPreloadOffset = index < state.activeIndex ? -1 : 1;
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
    _preferredPreloadOffset = 1;
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
      _schedulePreloadWindow(_openGeneration);
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
    final target = player.state.position + delta;
    await player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> seek(Duration position) async => _player?.seek(position);

  Future<void> applyPlaybackColorConfig() async {
    if (state.activeItem?.isVideo != true || _player == null) return;
    final position = _player!.state.position;
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
    _cancelScheduledPreload();
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
      isVideoReady: warmSlot?.firstFrameReady ?? false,
      isMuted: false,
      position: warmPlayerState?.position ?? Duration.zero,
      duration: warmPlayerState?.duration ?? Duration.zero,
    );
    await _cancelActiveSubscriptions();
    await previousSlot?.player.pause();
    if (generation != _openGeneration) return;
    // Release obsolete native video outputs while playback is paused. Doing
    // this from delayed background maintenance can interrupt active frames.
    await _prunePreloadWindow(generation);
    if (generation != _openGeneration) return;
    if (item == null || !item.isVideo) {
      unawaited(_runPoolMaintenance(generation));
      return;
    }
    if (forceReload) {
      await _removeSlot(item.path);
    }
    final slot = await _obtainSlot(item);
    if (generation != _openGeneration || slot == null) return;
    final player = slot.player;
    var videoController = slot.controller;
    if (videoController == null) {
      videoController = VideoController(player);
      slot.controller = videoController;
      // A preloaded slot is opened without a native video output to keep its
      // background work lightweight. macOS/libmpv does not reliably connect
      // an output attached after that open, so wait for the texture and reload
      // the source once when the slot becomes active.
      await videoController.platform.future;
      if (generation != _openGeneration || slot.disposed) return;
      await player.open(Media(slot.item.path), play: false);
      if (generation != _openGeneration || slot.disposed) return;
      slot.firstFrameReady = false;
    }
    _activeSlot = slot;
    _player = player;
    _videoController = videoController;
    final playerState = player.state;
    var lastPublishedPosition = playerState.position;
    state = state.copyWith(
      duration: playerState.duration,
      position: playerState.position,
      isVideoReady: slot.firstFrameReady,
    );
    unawaited(_markReadyAfterFirstFrame(slot, generation));
    _subscriptions.addAll([
      player.stream.playing.listen((playing) {
        if (generation != _openGeneration) return;
        state = state.copyWith(
          isPlaying: playing,
          position: playing ? state.position : player.state.position,
        );
      }),
      player.stream.position.listen((position) {
        if (generation != _openGeneration) return;
        final becameReady =
            !state.isVideoReady && position >= _readinessPositionFallback;
        final positionDelta = position - lastPublishedPosition;
        if (!becameReady &&
            positionDelta.abs() < _positionUiUpdateInterval &&
            position > Duration.zero) {
          return;
        }
        lastPublishedPosition = position;
        state = state.copyWith(
          position: position,
          isVideoReady: state.isVideoReady || becameReady,
        );
      }),
      player.stream.duration.listen((duration) {
        if (generation != _openGeneration) return;
        state = state.copyWith(duration: duration);
      }),
      player.stream.completed.listen((completed) {
        if (!completed || generation != _openGeneration) return;
        if (state.isLooping) return;
        final activeItem = state.activeItem;
        if (activeItem == null || !path.equals(activeItem.path, item.path)) {
          return;
        }
        state = state.copyWith(position: player.state.position);
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
    } else if (player.state.position > Duration.zero) {
      // A recently deactivated slot may not have reached its delayed reset yet.
      // Reset it before playback so rapid direction changes still start at zero.
      await player.seek(Duration.zero);
    }
    if (muted) {
      if (player.state.volume != 0) await player.setVolume(0);
      state = state.copyWith(isMuted: true);
    } else if (player.state.volume != 100) {
      await player.setVolume(100);
    }
    if (playWhenReady) await player.play();
    if (generation != _openGeneration) return;
    if (playWhenReady) {
      _schedulePoolMaintenance(generation);
    } else {
      unawaited(_runPoolMaintenance(generation));
    }
  }

  Future<void> _markReadyAfterFirstFrame(
    _VideoPlayerSlot slot,
    int generation,
  ) async {
    try {
      final controller = slot.controller;
      if (controller == null) return;
      await controller.waitUntilFirstFrameRendered.timeout(
        _activeFirstFrameTimeout,
      );
      if (slot.disposed) return;
      slot.firstFrameReady = true;
      if (generation == _openGeneration && identical(_activeSlot, slot)) {
        state = state.copyWith(isVideoReady: true);
      }
    } on TimeoutException {
      if (generation == _openGeneration &&
          identical(_activeSlot, slot) &&
          slot.player.state.position >= _readinessPositionFallback) {
        state = state.copyWith(isVideoReady: true);
      }
    } on Object catch (error) {
      if (!slot.disposed) {
        debugPrint('Could not observe first video frame: $error');
      }
    }
  }

  void _schedulePoolMaintenance(int generation) {
    _cancelScheduledPreload();
    _preloadTimer = Timer(_playbackStabilizationDelay, () {
      _preloadTimer = null;
      unawaited(_runPoolMaintenance(generation));
    });
  }

  void _schedulePreloadWindow(int generation) {
    if (state.activeItem?.isVideo == true && state.isPlaying) {
      _schedulePoolMaintenance(generation);
    } else {
      unawaited(_syncPreloadWindow(generation));
    }
  }

  void _cancelScheduledPreload() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
  }

  Future<void> _runPoolMaintenance(int generation) async {
    try {
      if (generation != _openGeneration) return;
      await _syncPreloadWindow(generation);
    } on Object catch (error) {
      if (generation == _openGeneration) {
        debugPrint('Could not maintain video preload pool: $error');
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
      await player.open(Media(slot.item.path), play: false);
      if (slot.disposed) return false;
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
    await _prunePreloadWindow(generation);
    if (generation != _openGeneration) return;
    final activeIndex = state.activeIndex;
    final activePath = state.activeItem?.path;
    final preferredIndex = activeIndex + _preferredPreloadOffset;
    final fallbackIndex = activeIndex - _preferredPreloadOffset;
    for (final (index, mayCreate) in [
      (preferredIndex, true),
      (fallbackIndex, false),
    ]) {
      if (generation != _openGeneration) return;
      if (index < 0 || index >= state.items.length) continue;
      final item = state.items[index];
      if (!item.isVideo || item.path == activePath) continue;
      if (!mayCreate && !_playerPool.containsKey(item.path)) continue;
      await _obtainSlot(item);
    }
  }

  Future<void> _prunePreloadWindow(int generation) async {
    if (generation != _openGeneration || state.items.isEmpty) return;
    final activeIndex = state.activeIndex;
    final retainedPaths = <String>{};
    for (final index in [activeIndex - 1, activeIndex, activeIndex + 1]) {
      if (index < 0 || index >= state.items.length) continue;
      final item = state.items[index];
      if (item.isVideo) retainedPaths.add(item.path);
    }
    final obsoleteSlots = _playerPool.entries
        .where((entry) => !retainedPaths.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    for (final slot in obsoleteSlots) {
      if (generation != _openGeneration) return;
      await _removeSlot(slot.item.path, expected: slot);
    }
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
    _cancelScheduledPreload();
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
  VideoController? controller;
  bool prepared = false;
  bool firstFrameReady = false;
  bool disposed = false;

  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    await player.dispose();
  }
}
