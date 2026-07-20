import '../../domain/entities/theme_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

final class SaveThemePreferences {
  const SaveThemePreferences(this._repository);

  final SettingsRepository _repository;

  Future<void> call(ThemePreferences preferences) {
    return _repository.saveThemePreferences(preferences);
  }
}
