import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../data/repositories/media_kit_duration_repository.dart';
import '../../data/repositories/platform_seek_preview_frame_repository.dart';
import '../../data/services/media_kit_video_color_configurator.dart';
import '../../domain/repositories/media_duration_repository.dart';
import '../../domain/repositories/seek_preview_frame_repository.dart';
import '../../domain/value_objects/media_playback_config.dart';
import '../services/media_duration_job_scheduler.dart';

final mediaPlaybackConfigProvider =
    NotifierProvider<MediaPlaybackConfigNotifier, MediaPlaybackConfig>(
      MediaPlaybackConfigNotifier.new,
    );

final class MediaPlaybackConfigNotifier extends Notifier<MediaPlaybackConfig> {
  @override
  MediaPlaybackConfig build() => const MediaPlaybackConfig();

  void toggleHdr() {
    state = state.copyWith(hdrEnabled: !state.hdrEnabled);
  }
}

final mediaKitVideoColorConfiguratorProvider = Provider(
  (ref) =>
      MediaKitVideoColorConfigurator(ref.watch(mediaPlaybackConfigProvider)),
);

final mediaDurationRepositoryProvider = Provider<MediaDurationRepository>(
  (ref) => MediaKitDurationRepository(),
);

final seekPreviewFrameRepositoryProvider = Provider<SeekPreviewFrameRepository>(
  (ref) => PlatformSeekPreviewFrameRepository(),
);

final mediaDurationJobSchedulerProvider = Provider(
  (ref) =>
      MediaDurationJobScheduler(ref.watch(mediaDurationRepositoryProvider)),
);

final videoDurationProvider = FutureProvider.autoDispose
    .family<Duration?, MediaItem>((ref, item) {
      final request = ref
          .read(mediaDurationJobSchedulerProvider)
          .getDuration(item);
      ref.onDispose(request.cancel);
      return request.result;
    });
