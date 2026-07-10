import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../shared/models/gallery_item.dart';
import 'media_detail_state.dart';

final mediaDetailControllerProvider =
    NotifierProvider.autoDispose<MediaDetailController, MediaDetailState>(
      MediaDetailController.new,
    );

class MediaDetailController extends Notifier<MediaDetailState> {
  Player? _player;
  VideoController? _videoController;
  final _subscriptions = <StreamSubscription<Object?>>[];
  int _openGeneration = 0;

  VideoController? get videoController => _videoController;

  @override
  MediaDetailState build() {
    ref.onDispose(() {
      _openGeneration++;
      unawaited(_disposePlayer());
    });
    return const MediaDetailState();
  }

  Future<void> configure(List<MediaItem> items, int initialIndex) async {
    state = MediaDetailState(
      items: items,
      activeIndex: initialIndex.clamp(0, items.length - 1),
    );
    await _openActive();
  }

  Future<void> next() async {
    if (!state.hasNext) return;
    state = state.copyWith(activeIndex: state.activeIndex + 1);
    await _openActive();
  }

  Future<void> previous() async {
    if (!state.hasPrevious) return;
    state = state.copyWith(activeIndex: state.activeIndex - 1);
    await _openActive();
  }

  Future<void> select(int index) async {
    if (index == state.activeIndex) return;
    state = state.copyWith(activeIndex: index);
    await _openActive();
  }

  Future<void> openMedia(MediaItem item) async {
    final existingIndex = state.items.indexWhere(
      (entry) => entry.path == item.path,
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

  Future<void> togglePlay() async => _player?.playOrPause();

  Future<void> toggleMute() async {
    final player = _player;
    if (player == null) return;
    await player.setVolume(state.isMuted ? 100 : 0);
    state = state.copyWith(isMuted: !state.isMuted);
  }

  Future<void> seekBy(Duration delta) async {
    final player = _player;
    if (player == null) return;
    final target = state.position + delta;
    await player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> seek(Duration position) async => _player?.seek(position);

  Future<void> _openActive() async {
    final generation = ++_openGeneration;
    await _disposePlayer();
    if (generation != _openGeneration) return;
    final item = state.activeItem;
    state = state.copyWith(
      isPlaying: false,
      isMuted: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
    if (item == null || !item.isVideo) return;
    final player = Player();
    _player = player;
    _videoController = VideoController(player);
    _subscriptions.addAll([
      player.stream.playing.listen((playing) {
        state = state.copyWith(isPlaying: playing);
      }),
      player.stream.position.listen((position) {
        state = state.copyWith(position: position);
      }),
      player.stream.duration.listen((duration) {
        state = state.copyWith(duration: duration);
      }),
    ]);
    await player.open(Media(item.path), play: true);
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
