import '../entities/gallery_item.dart';

abstract interface class GalleryRepository {
  Future<List<GalleryItem>> readDirectory(String directoryPath);

  Future<List<MediaItem>> readMediaRecursively(String rootPath);
}
