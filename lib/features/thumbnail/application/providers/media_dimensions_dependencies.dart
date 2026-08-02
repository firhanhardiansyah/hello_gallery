import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../data/repositories/media_dimensions_repository_impl.dart';
import '../../domain/repositories/media_dimensions_repository.dart';
import 'thumbnail_dependencies.dart';

const fallbackMediaAspectRatio = 3 / 4;

final mediaDimensionsRepositoryProvider = Provider<MediaDimensionsRepository>(
  (ref) => MediaDimensionsRepositoryImpl(),
);

final mediaAspectRatioProvider = FutureProvider.autoDispose
    .family<double, MediaItem>((ref, item) async {
      final thumbnailPath = item.isVideo
          ? await ref.watch(videoThumbnailProvider(item).future)
          : null;
      final dimensions = await ref
          .read(mediaDimensionsRepositoryProvider)
          .getDimensions(item, videoThumbnailPath: thumbnailPath);
      return dimensions?.aspectRatio ?? fallbackMediaAspectRatio;
    });
