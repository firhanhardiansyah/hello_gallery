import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../services/gallery_directory_cache.dart';

final class ReadGalleryDirectory {
  const ReadGalleryDirectory(this._repository, this._cache);

  final GalleryRepository _repository;
  final GalleryDirectoryCache _cache;

  Future<List<GalleryItem>> call(
    String directoryPath, {
    bool forceRefresh = false,
  }) {
    return _cache.read(
      directoryPath,
      forceRefresh: forceRefresh,
      load: () => _repository.readDirectory(directoryPath),
    );
  }

  List<GalleryItem>? getCached(String directoryPath) {
    return _cache.get(directoryPath);
  }

  void invalidate(String directoryPath) => _cache.invalidate(directoryPath);

  void clearCache() => _cache.clear();
}
