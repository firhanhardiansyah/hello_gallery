import '../../domain/repositories/folder_management_repository.dart';
import '../data_sources/local_folder_management_data_source.dart';

final class FolderManagementRepositoryImpl
    implements FolderManagementRepository {
  const FolderManagementRepositoryImpl(this._dataSource);

  final LocalFolderManagementDataSource _dataSource;

  @override
  Future<bool> entityExists(String entityPath) {
    return _dataSource.entityExists(entityPath);
  }

  @override
  Future<void> createFolder(String folderPath) {
    return _dataSource.createFolder(folderPath);
  }

  @override
  Future<void> renameFolder(String oldPath, String newPath) {
    return _dataSource.renameFolder(oldPath, newPath);
  }

  @override
  Future<void> moveFolderToTrash(String folderPath) {
    return _dataSource.moveFolderToTrash(folderPath);
  }
}
