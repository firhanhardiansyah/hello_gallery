abstract interface class FolderManagementRepository {
  Future<bool> entityExists(String entityPath);

  Future<void> createFolder(String folderPath);

  Future<void> renameFolder(String oldPath, String newPath);

  Future<void> moveFolderToTrash(String folderPath);
}
