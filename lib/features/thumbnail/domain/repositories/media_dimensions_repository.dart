import '../../../gallery/domain/entities/gallery_item.dart';
import '../value_objects/media_dimensions.dart';

abstract interface class MediaDimensionsRepository {
  Future<MediaDimensions?> getDimensions(
    MediaItem item, {
    String? videoThumbnailPath,
  });
}
