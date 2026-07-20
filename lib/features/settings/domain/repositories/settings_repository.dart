abstract interface class SettingsRepository {
  Future<String?> readRootPath();

  Future<String?> readRootBookmark();

  Future<void> saveRootPath(String path, {String? bookmark});
}
