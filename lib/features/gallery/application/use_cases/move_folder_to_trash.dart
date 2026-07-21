import 'package:path/path.dart' as path;

import '../../domain/repositories/folder_management_repository.dart';
import 'create_folder.dart';

final class MoveFolderToTrash {
  const MoveFolderToTrash(this._repository);

  final FolderManagementRepository _repository;

  Future<void> call({
    required String rootPath,
    required String folderPath,
  }) async {
    final root = path.normalize(rootPath);
    final target = path.normalize(folderPath);
    if (path.equals(root, target)) {
      throw ArgumentError('The gallery root cannot be moved to Trash.');
    }
    ensurePathInsideRoot(root, target);
    if (!await _repository.entityExists(target)) {
      throw ArgumentError('Folder no longer exists.');
    }
    await _repository.moveFolderToTrash(target);
  }
}
