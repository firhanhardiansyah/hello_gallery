import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/settings_dependencies.dart';
import '../../domain/entities/theme_preferences.dart';
import '../../domain/value_objects/app_appearance_mode.dart';
import '../../domain/value_objects/app_color_theme.dart';
import '../states/settings_ui_state.dart';

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsUiState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsUiState> {
  @override
  SettingsUiState build() {
    Future.microtask(_load);
    return const SettingsUiState();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ref.read(loadGalleryRootProvider)(),
      ref.read(loadThemePreferencesProvider)(),
    ]);
    final theme = results[1] as ThemePreferences;
    state = SettingsUiState(
      rootPath: results[0] as String?,
      isLoading: false,
      appearanceMode: theme.appearanceMode,
      colorTheme: theme.colorTheme,
    );
  }

  Future<bool> chooseRootFolder() async {
    try {
      final selectedPath = await ref.read(chooseGalleryRootProvider)(
        initialDirectory: state.rootPath,
      );
      if (selectedPath == null) return false;
      state = state.copyWith(rootPath: selectedPath, isLoading: false);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> setAppearanceMode(AppAppearanceMode mode) async {
    state = state.copyWith(appearanceMode: mode);
    await _saveThemePreferences();
  }

  Future<void> setColorTheme(AppColorTheme theme) async {
    state = state.copyWith(colorTheme: theme);
    await _saveThemePreferences();
  }

  Future<void> _saveThemePreferences() {
    return ref.read(saveThemePreferencesProvider)(
      ThemePreferences(
        appearanceMode: state.appearanceMode,
        colorTheme: state.colorTheme,
      ),
    );
  }
}
