import '../../../gallery/domain/entities/gallery_item.dart';

abstract interface class ThumbnailRepository {
  Future<String?> findCachedThumbnail(MediaItem item);

  Future<String?> getThumbnail(MediaItem item);

  Future<void> removeCachedThumbnail(MediaItem item);
}
