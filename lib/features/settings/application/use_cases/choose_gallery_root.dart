import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/root_folder_access.dart';

final class ChooseGalleryRoot {
  const ChooseGalleryRoot(this._repository, this._rootFolderAccess);

  final SettingsRepository _repository;
  final RootFolderAccess _rootFolderAccess;

  Future<String?> call({String? initialDirectory}) async {
    final selection = await _rootFolderAccess.choose(
      initialDirectory: initialDirectory,
    );
    if (selection == null) return null;
    await _repository.saveRootPath(
      selection.path,
      bookmark: selection.bookmark,
    );
    return selection.path;
  }
}
