import 'package:path/path.dart' as path;

enum GalleryItemType { folder, image, video }

sealed class GalleryItem {
  const GalleryItem({
    required this.path,
    required this.name,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final DateTime modifiedAt;
  GalleryItemType get type;
}

class GalleryFolder extends GalleryItem {
  const GalleryFolder({
    required super.path,
    required super.name,
    required super.modifiedAt,
  });

  @override
  GalleryItemType get type => GalleryItemType.folder;
}

class MediaItem extends GalleryItem {
  const MediaItem({
    required super.path,
    required super.name,
    required super.modifiedAt,
    required this.mediaType,
    this.sizeBytes = 0,
  });

  final GalleryItemType mediaType;
  final int sizeBytes;

  bool get isVideo => mediaType == GalleryItemType.video;
  String get extension => path.extension(this.path).toLowerCase();

  @override
  GalleryItemType get type => mediaType;
}
