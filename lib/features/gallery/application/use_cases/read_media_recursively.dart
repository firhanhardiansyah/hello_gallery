import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

final class ReadMediaRecursively {
  const ReadMediaRecursively(this._repository);

  final GalleryRepository _repository;

  Future<List<MediaItem>> call(String rootPath) {
    return _repository.readMediaRecursively(rootPath);
  }
}
