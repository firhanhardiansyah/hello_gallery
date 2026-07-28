import 'dart:async';

import 'package:media_kit/media_kit.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../domain/repositories/media_duration_repository.dart';

final class MediaKitDurationRepository implements MediaDurationRepository {
  @override
  Future<Duration?> readVideoDuration(MediaItem item) async {
    if (!item.isVideo) return null;

    final player = Player(
      configuration: const PlayerConfiguration(muted: true),
    );
    try {
      final durationReady = player.stream.duration.firstWhere(
        (duration) => duration > Duration.zero,
      );
      await player.open(Media(item.path), play: false);
      final currentDuration = player.state.duration;
      if (currentDuration > Duration.zero) return currentDuration;
      return await durationReady.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return null;
    } finally {
      await player.dispose();
    }
  }
}
