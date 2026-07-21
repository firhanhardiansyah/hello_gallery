import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/repositories/folder_management_repository.dart';
import '../../domain/rules/folder_name_rules.dart';

final class CreateFolder {
  const CreateFolder(this._repository);

  final FolderManagementRepository _repository;

  Future<String> call({
    required String rootPath,
    required String parentPath,
    required String folderName,
  }) async {
    ensurePathInsideRoot(rootPath, parentPath);
    final nameError = FolderNameRules.validate(folderName);
    if (nameError != null) throw ArgumentError(nameError);
    final folderPath = path.join(parentPath, folderName.trim());
    if (await _repository.entityExists(folderPath)) {
      throw FileSystemException(
        'A file or folder already uses this name',
        folderPath,
      );
    }
    await _repository.createFolder(folderPath);
    return folderPath;
  }
}

void ensurePathInsideRoot(String rootPath, String candidatePath) {
  final root = path.normalize(rootPath);
  final candidate = path.normalize(candidatePath);
  if (!path.equals(root, candidate) && !path.isWithin(root, candidate)) {
    throw ArgumentError('Folder must be inside the gallery root.');
  }
}
