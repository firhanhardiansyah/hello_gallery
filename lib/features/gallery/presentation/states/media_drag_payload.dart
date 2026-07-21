import '../../domain/entities/gallery_item.dart';

class MediaDragPayload {
  const MediaDragPayload(this.items);

  final List<MediaItem> items;

  int get count => items.length;
}
