import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsRepositoryProvider = Provider(SettingsRepository.new);

class SettingsRepository {
  SettingsRepository(this.ref);

  final Ref ref;
  static const _rootPathKey = 'gallery_root_path';

  Future<String?> readRootPath() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_rootPathKey);
  }

  Future<void> saveRootPath(String path) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_rootPathKey, path);
  }
}
