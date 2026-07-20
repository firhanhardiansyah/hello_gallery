import '../value_objects/app_appearance_mode.dart';
import '../value_objects/app_color_theme.dart';

final class ThemePreferences {
  const ThemePreferences({
    this.appearanceMode = AppAppearanceMode.system,
    this.colorTheme = AppColorTheme.indigo,
  });

  final AppAppearanceMode appearanceMode;
  final AppColorTheme colorTheme;
}
