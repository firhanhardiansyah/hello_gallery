import '../../../gallery/domain/entities/gallery_item.dart';

abstract interface class MediaDurationRepository {
  Future<Duration?> readVideoDuration(MediaItem item);
}
