import '../../domain/repositories/media_management_repository.dart';
import '../data_sources/local_media_management_data_source.dart';

final class MediaManagementRepositoryImpl implements MediaManagementRepository {
  const MediaManagementRepositoryImpl(this._dataSource);

  final LocalMediaManagementDataSource _dataSource;

  @override
  Future<bool> fileExists(String filePath) => _dataSource.fileExists(filePath);

  @override
  Future<bool> entityExists(String entityPath) {
    return _dataSource.entityExists(entityPath);
  }

  @override
  Future<void> renameMedia(String oldPath, String newPath) {
    return _dataSource.renameMedia(oldPath, newPath);
  }

  @override
  Future<void> moveMediaToTrash(String filePath) {
    return _dataSource.moveMediaToTrash(filePath);
  }
}
