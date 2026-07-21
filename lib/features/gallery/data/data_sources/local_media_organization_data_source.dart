import 'dart:io';

class LocalMediaOrganizationDataSource {
  const LocalMediaOrganizationDataSource();

  Future<bool> fileExists(String filePath) => File(filePath).exists();

  Future<void> createDirectory(String directoryPath) async {
    await Directory(directoryPath).create(recursive: true);
  }

  Future<void> moveFile(String sourcePath, String destinationPath) async {
    await File(sourcePath).rename(destinationPath);
  }
}
