import '../../domain/repositories/media_organization_repository.dart';
import '../data_sources/local_media_organization_data_source.dart';

final class MediaOrganizationRepositoryImpl
    implements MediaOrganizationRepository {
  const MediaOrganizationRepositoryImpl(this._dataSource);

  final LocalMediaOrganizationDataSource _dataSource;

  @override
  Future<bool> fileExists(String filePath) => _dataSource.fileExists(filePath);

  @override
  Future<void> createDirectory(String directoryPath) {
    return _dataSource.createDirectory(directoryPath);
  }

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) {
    return _dataSource.moveFile(sourcePath, destinationPath);
  }
}
