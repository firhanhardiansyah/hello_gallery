abstract interface class MediaOrganizationRepository {
  Future<bool> fileExists(String filePath);

  Future<void> createDirectory(String directoryPath);

  Future<void> moveFile(String sourcePath, String destinationPath);
}
