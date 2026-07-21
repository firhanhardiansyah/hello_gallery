import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/repositories/folder_management_repository.dart';
import '../../domain/rules/folder_name_rules.dart';
import 'create_folder.dart';

final class RenameFolder {
  const RenameFolder(this._repository);

  final FolderManagementRepository _repository;

  Future<String> call({
    required String rootPath,
    required String folderPath,
    required String newName,
  }) async {
    final root = path.normalize(rootPath);
    final source = path.normalize(folderPath);
    if (path.equals(root, source)) {
      throw ArgumentError('The gallery root cannot be renamed.');
    }
    ensurePathInsideRoot(root, source);
    final nameError = FolderNameRules.validate(newName);
    if (nameError != null) throw ArgumentError(nameError);
    final destination = path.join(path.dirname(source), newName.trim());
    if (path.equals(source, destination)) return source;
    if (await _repository.entityExists(destination)) {
      throw FileSystemException(
        'A file or folder already uses this name',
        destination,
      );
    }
    await _repository.renameFolder(source, destination);
    return destination;
  }
}
