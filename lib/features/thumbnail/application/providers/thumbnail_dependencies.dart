import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../data/repositories/thumbnail_repository_impl.dart';
import '../../domain/repositories/thumbnail_repository.dart';
import '../services/thumbnail_job_scheduler.dart';

final thumbnailRepositoryProvider = Provider<ThumbnailRepository>(
  (ref) => ThumbnailRepositoryImpl(),
);

final thumbnailJobSchedulerProvider = Provider(
  (ref) => ThumbnailJobScheduler(ref.watch(thumbnailRepositoryProvider)),
);

final videoThumbnailProvider = FutureProvider.family<String?, MediaItem>(
  (ref, item) => ref.read(thumbnailJobSchedulerProvider).getThumbnail(item),
);

final cachedVideoThumbnailProvider = FutureProvider.family<String?, MediaItem>(
  (ref, item) =>
      ref.read(thumbnailJobSchedulerProvider).findCachedThumbnail(item),
);
