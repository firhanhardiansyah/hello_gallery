import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/root_folder_access.dart';

final class LoadGalleryRoot {
  const LoadGalleryRoot(this._repository, this._rootFolderAccess);

  final SettingsRepository _repository;
  final RootFolderAccess _rootFolderAccess;

  Future<String?> call() async {
    return _rootFolderAccess.restore(
      path: await _repository.readRootPath(),
      bookmark: await _repository.readRootBookmark(),
    );
  }
}
