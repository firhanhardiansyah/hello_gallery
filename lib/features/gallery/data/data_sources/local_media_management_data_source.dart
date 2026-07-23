import 'dart:io';

import '../services/platform_folder_trash.dart';

final class LocalMediaManagementDataSource {
  const LocalMediaManagementDataSource(this._trash);

  final PlatformFolderTrash _trash;

  Future<bool> fileExists(String filePath) => File(filePath).exists();

  Future<bool> entityExists(String entityPath) async {
    return await FileSystemEntity.type(entityPath, followLinks: false) !=
        FileSystemEntityType.notFound;
  }

  Future<void> renameMedia(String oldPath, String newPath) async {
    await File(oldPath).rename(newPath);
  }

  Future<void> moveMediaToTrash(String filePath) {
    return _trash.moveToTrash(filePath);
  }
}
