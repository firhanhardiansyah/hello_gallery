import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../data/data_sources/platform_media_dimensions_data_source.dart';
import '../../data/repositories/media_dimensions_repository_impl.dart';
import '../../domain/repositories/media_dimensions_repository.dart';
import 'thumbnail_dependencies.dart';

const fallbackMediaAspectRatio = 3 / 4;
const _mediaAspectRatioRetention = Duration(minutes: 10);

final platformMediaDimensionsDataSourceProvider = Provider(
  (ref) => const PlatformMediaDimensionsDataSource(),
);

final mediaDimensionsRepositoryProvider = Provider<MediaDimensionsRepository>(
  (ref) => MediaDimensionsRepositoryImpl(
    videoReader: ref
        .watch(platformMediaDimensionsDataSourceProvider)
        .readVideoDimensions,
  ),
);

final mediaAspectRatioProvider = FutureProvider.autoDispose
    .family<double, MediaItem>((ref, item) async {
      final cacheLink = ref.keepAlive();
      final cacheTimer = Timer(_mediaAspectRatioRetention, cacheLink.close);
      ref.onDispose(cacheTimer.cancel);
      final repository = ref.read(mediaDimensionsRepositoryProvider);
      if (item.isVideo) {
        final nativeDimensions = await repository.getDimensions(item);
        if (nativeDimensions != null) return nativeDimensions.aspectRatio;
      }
      final thumbnailPath = item.isVideo
          ? await ref.watch(videoThumbnailProvider(item).future)
          : null;
      for (var attempt = 0; attempt < 3; attempt++) {
        final dimensions = await repository.getDimensions(
          item,
          videoThumbnailPath: thumbnailPath,
        );
        if (dimensions != null) return dimensions.aspectRatio;
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 80 * (attempt + 1)),
          );
        }
      }
      return fallbackMediaAspectRatio;
    });
