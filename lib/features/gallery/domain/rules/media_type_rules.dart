import 'package:path/path.dart' as path;

import '../entities/gallery_item.dart';

abstract final class MediaTypeRules {
  static const imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
    '.tif',
    '.tiff',
  };

  static const videoExtensions = {
    '.mp4',
    '.mkv',
    '.mov',
    '.avi',
    '.webm',
    '.m4v',
    '.wmv',
  };

  static GalleryItemType? fromPath(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    if (imageExtensions.contains(extension)) return GalleryItemType.image;
    if (videoExtensions.contains(extension)) return GalleryItemType.video;
    return null;
  }
}
