import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/repositories/media_management_repository.dart';
import '../../domain/rules/media_name_rules.dart';
import 'create_folder.dart';

final class RenameMedia {
  const RenameMedia(this._repository);

  final MediaManagementRepository _repository;

  Future<String> call({
    required String rootPath,
    required String mediaPath,
    required String newBaseName,
  }) async {
    final root = path.normalize(rootPath);
    final source = path.normalize(mediaPath);
    ensurePathInsideRoot(root, source);
    final nameError = MediaNameRules.validateBaseName(newBaseName);
    if (nameError != null) throw ArgumentError(nameError);
    if (!await _repository.fileExists(source)) {
      throw ArgumentError('File no longer exists.');
    }

    final extension = path.extension(source);
    final destination = path.join(
      path.dirname(source),
      '${newBaseName.trim()}$extension',
    );
    if (path.equals(source, destination)) return source;
    if (await _repository.entityExists(destination)) {
      throw FileSystemException(
        'A file or folder already uses this name',
        destination,
      );
    }
    await _repository.renameMedia(source, destination);
    return destination;
  }
}
