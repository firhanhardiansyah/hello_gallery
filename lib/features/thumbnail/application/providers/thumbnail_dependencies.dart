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

final videoThumbnailProvider = FutureProvider.autoDispose
    .family<String?, MediaItem>((ref, item) {
      final scheduler = ref.read(thumbnailJobSchedulerProvider);
      final resolvedThumbnail = scheduler.findResolvedThumbnail(item);
      if (resolvedThumbnail != null) return resolvedThumbnail;
      return _loadVideoThumbnail(ref, scheduler, item);
    });

Future<String?> _loadVideoThumbnail(
  Ref ref,
  ThumbnailJobScheduler scheduler,
  MediaItem item,
) async {
  ThumbnailRequest? activeRequest;
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    activeRequest?.cancel();
  });

  while (!disposed) {
    final request = scheduler.getThumbnail(item);
    activeRequest = request;
    final thumbnailPath = await request.result;
    if (!request.wasCancelled) return thumbnailPath;
    if (disposed) break;
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
  return null;
}

final cachedVideoThumbnailProvider = FutureProvider.autoDispose
    .family<String?, MediaItem>((ref, item) {
      final scheduler = ref.read(thumbnailJobSchedulerProvider);
      final resolvedThumbnail = scheduler.findResolvedThumbnail(item);
      return resolvedThumbnail ?? scheduler.findCachedThumbnail(item);
    });
