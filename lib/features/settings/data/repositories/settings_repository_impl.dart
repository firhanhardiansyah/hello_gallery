import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  static const _rootPathKey = 'gallery_root_path';
  static const _rootBookmarkKey = 'gallery_root_bookmark';

  @override
  Future<String?> readRootPath() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_rootPathKey);
  }

  @override
  Future<String?> readRootBookmark() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_rootBookmarkKey);
  }

  @override
  Future<void> saveRootPath(String path, {String? bookmark}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_rootPathKey, path);
    if (bookmark == null) {
      await preferences.remove(_rootBookmarkKey);
    } else {
      await preferences.setString(_rootBookmarkKey, bookmark);
    }
  }
}
