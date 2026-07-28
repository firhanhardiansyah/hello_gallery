import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../data/repositories/media_kit_duration_repository.dart';
import '../../domain/repositories/media_duration_repository.dart';
import '../services/media_duration_job_scheduler.dart';

final mediaDurationRepositoryProvider = Provider<MediaDurationRepository>(
  (ref) => MediaKitDurationRepository(),
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
