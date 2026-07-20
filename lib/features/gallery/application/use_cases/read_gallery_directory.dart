import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

final class ReadGalleryDirectory {
  const ReadGalleryDirectory(this._repository);

  final GalleryRepository _repository;

  Future<List<GalleryItem>> call(String directoryPath) {
    return _repository.readDirectory(directoryPath);
  }
}
