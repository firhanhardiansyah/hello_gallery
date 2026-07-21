import 'dart:io';

import '../services/platform_folder_trash.dart';

class LocalFolderManagementDataSource {
  const LocalFolderManagementDataSource(this._trash);

  final PlatformFolderTrash _trash;

  Future<bool> entityExists(String entityPath) async {
    final type = await FileSystemEntity.type(entityPath, followLinks: false);
    return type != FileSystemEntityType.notFound;
  }

  Future<void> createFolder(String folderPath) async {
    await Directory(folderPath).create();
  }

  Future<void> renameFolder(String oldPath, String newPath) async {
    await Directory(oldPath).rename(newPath);
  }

  Future<void> moveFolderToTrash(String folderPath) {
    return _trash.moveToTrash(folderPath);
  }
}
