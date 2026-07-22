import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/settings_dependencies.dart';
import '../../domain/entities/gallery_view_preferences.dart';
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
      ref.read(loadGalleryViewPreferencesProvider)(),
    ]);
    final theme = results[1] as ThemePreferences;
    final galleryView = results[2] as GalleryViewPreferences;
    state = SettingsUiState(
      rootPath: results[0] as String?,
      isLoading: false,
      appearanceMode: theme.appearanceMode,
      colorTheme: theme.colorTheme,
      showItemNames: galleryView.showItemNames,
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

  Future<void> setShowItemNames(bool showItemNames) async {
    state = state.copyWith(showItemNames: showItemNames);
    await ref.read(saveGalleryViewPreferencesProvider)(
      GalleryViewPreferences(showItemNames: showItemNames),
    );
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
