abstract interface class MediaManagementRepository {
  Future<bool> fileExists(String filePath);

  Future<bool> entityExists(String entityPath);

  Future<void> renameMedia(String oldPath, String newPath);

  Future<void> moveMediaToTrash(String filePath);
}
