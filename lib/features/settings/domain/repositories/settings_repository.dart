import '../entities/theme_preferences.dart';
import '../value_objects/app_appearance_mode.dart';
import '../value_objects/app_color_theme.dart';

abstract interface class SettingsRepository {
  Future<String?> readRootPath();

  Future<String?> readRootBookmark();

  Future<void> saveRootPath(String path, {String? bookmark});

  Future<AppAppearanceMode> readAppearanceMode();

  Future<AppColorTheme> readColorTheme();

  Future<void> saveThemePreferences(ThemePreferences preferences);
}
