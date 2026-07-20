import '../../domain/entities/gallery_item.dart';

class MediaPreviewSelection {
  const MediaPreviewSelection({
    required this.items,
    required this.initialIndex,
    required this.folderPath,
    required this.requestedMediaPath,
  });

  final List<MediaItem> items;
  final int initialIndex;
  final String folderPath;
  final String requestedMediaPath;
}
