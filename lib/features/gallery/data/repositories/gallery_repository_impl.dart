import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../data_sources/local_gallery_data_source.dart';

final class GalleryRepositoryImpl implements GalleryRepository {
  const GalleryRepositoryImpl(this._dataSource);

  final LocalGalleryDataSource _dataSource;

  @override
  Future<List<GalleryItem>> readDirectory(String path) {
    return _dataSource.scan(path);
  }

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) {
    return _dataSource.scanMediaRecursively(rootPath);
  }
}
