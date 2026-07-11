import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsRepositoryProvider = Provider(SettingsRepository.new);

class SettingsRepository {
  SettingsRepository(this.ref);

  final Ref ref;
  static const _rootPathKey = 'gallery_root_path';
  static const _rootBookmarkKey = 'gallery_root_bookmark';

  Future<String?> readRootPath() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_rootPathKey);
  }

  Future<String?> readRootBookmark() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_rootBookmarkKey);
  }

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
