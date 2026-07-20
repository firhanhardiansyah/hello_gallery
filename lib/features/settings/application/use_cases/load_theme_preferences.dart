import '../../domain/entities/theme_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

final class LoadThemePreferences {
  const LoadThemePreferences(this._repository);

  final SettingsRepository _repository;

  Future<ThemePreferences> call() async {
    return ThemePreferences(
      appearanceMode: await _repository.readAppearanceMode(),
      colorTheme: await _repository.readColorTheme(),
    );
  }
}
