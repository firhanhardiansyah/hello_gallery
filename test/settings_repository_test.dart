import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:hello_gallery/features/settings/domain/entities/theme_preferences.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_appearance_mode.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('theme preferences default to system and indigo', () async {
    final repository = SettingsRepositoryImpl();

    expect(await repository.readAppearanceMode(), AppAppearanceMode.system);
    expect(await repository.readColorTheme(), AppColorTheme.indigo);
  });

  test('theme preferences persist selected values', () async {
    final repository = SettingsRepositoryImpl();

    await repository.saveThemePreferences(
      const ThemePreferences(
        appearanceMode: AppAppearanceMode.dark,
        colorTheme: AppColorTheme.pink,
      ),
    );

    expect(await repository.readAppearanceMode(), AppAppearanceMode.dark);
    expect(await repository.readColorTheme(), AppColorTheme.pink);
  });

  test('legacy blue preference migrates to emerald', () async {
    SharedPreferences.setMockInitialValues({'color_theme': 'blue'});
    final repository = SettingsRepositoryImpl();

    expect(await repository.readColorTheme(), AppColorTheme.emerald);
  });
}
