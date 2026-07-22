import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/gallery_view_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/theme_preferences.dart';
import '../../domain/value_objects/app_appearance_mode.dart';
import '../../domain/value_objects/app_color_theme.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  static const _rootPathKey = 'gallery_root_path';
  static const _rootBookmarkKey = 'gallery_root_bookmark';
  static const _appearanceModeKey = 'appearance_mode';
  static const _colorThemeKey = 'color_theme';
  static const _showItemNamesKey = 'show_item_names';

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

  @override
  Future<AppAppearanceMode> readAppearanceMode() async {
    final preferences = await SharedPreferences.getInstance();
    return AppAppearanceMode.fromStorage(
      preferences.getString(_appearanceModeKey),
    );
  }

  @override
  Future<AppColorTheme> readColorTheme() async {
    final preferences = await SharedPreferences.getInstance();
    return AppColorTheme.fromStorage(preferences.getString(_colorThemeKey));
  }

  @override
  Future<void> saveThemePreferences(ThemePreferences preferences) async {
    final storage = await SharedPreferences.getInstance();
    await Future.wait([
      storage.setString(_appearanceModeKey, preferences.appearanceMode.name),
      storage.setString(_colorThemeKey, preferences.colorTheme.name),
    ]);
  }

  @override
  Future<GalleryViewPreferences> readGalleryViewPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return GalleryViewPreferences(
      showItemNames: preferences.getBool(_showItemNamesKey) ?? true,
    );
  }

  @override
  Future<void> saveGalleryViewPreferences(
    GalleryViewPreferences preferences,
  ) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_showItemNamesKey, preferences.showItemNames);
  }
}
