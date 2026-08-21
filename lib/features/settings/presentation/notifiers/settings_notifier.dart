import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/settings_dependencies.dart';
import '../../domain/entities/gallery_view_preferences.dart';
import '../../domain/entities/theme_preferences.dart';
import '../../domain/value_objects/app_appearance_mode.dart';
import '../../domain/value_objects/app_color_theme.dart';
import '../../../gallery/domain/value_objects/gallery_item_extent.dart';
import '../../../gallery/domain/value_objects/gallery_layout_mode.dart';
import '../../../gallery/domain/value_objects/gallery_sort.dart';
import '../../../gallery/domain/value_objects/gallery_style_level.dart';
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
    state = state.copyWith(loadState: const SettingsLoadState.loading());
    try {
      final results = await Future.wait([
        ref.read(loadGalleryRootProvider)(),
        ref.read(loadThemePreferencesProvider)(),
        ref.read(loadGalleryViewPreferencesProvider)(),
      ]);
      final rootPath = results[0] as String?;
      final theme = results[1] as ThemePreferences;
      final galleryView = results[2] as GalleryViewPreferences;
      state = SettingsUiState(
        loadState: rootPath == null
            ? const SettingsLoadState.rootRequired()
            : SettingsLoadState.ready(rootPath),
        appearanceMode: theme.appearanceMode,
        colorTheme: theme.colorTheme,
        showItemNames: galleryView.showItemNames,
        galleryLayoutMode: galleryView.layoutMode,
        galleryItemExtent: galleryView.itemExtent,
        gallerySort: galleryView.sort,
        galleryGridSpacing: galleryView.gridSpacing,
        galleryCornerRadius: galleryView.cornerRadius,
      );
    } on Object catch (error) {
      state = state.copyWith(loadState: SettingsLoadState.error('$error'));
    }
  }

  Future<void> reload() => _load();

  Future<bool> chooseRootFolder() async {
    try {
      final selectedPath = await ref.read(chooseGalleryRootProvider)(
        initialDirectory: state.rootPath,
      );
      if (selectedPath == null) return false;
      state = state.copyWith(loadState: SettingsLoadState.ready(selectedPath));
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
    await _saveGalleryViewPreferences();
  }

  Future<void> setGalleryLayoutMode(GalleryLayoutMode layoutMode) async {
    state = state.copyWith(galleryLayoutMode: layoutMode);
    await _saveGalleryViewPreferences();
  }

  Future<void> setGallerySort(GallerySort sort) async {
    state = state.copyWith(gallerySort: sort);
    await _saveGalleryViewPreferences();
  }

  Future<void> setGalleryGridSpacing(GalleryStyleLevel level) async {
    if (state.galleryGridSpacing == level) return;
    state = state.copyWith(galleryGridSpacing: level);
    await _saveGalleryViewPreferences();
  }

  Future<void> setGalleryCornerRadius(GalleryStyleLevel level) async {
    if (state.galleryCornerRadius == level) return;
    state = state.copyWith(galleryCornerRadius: level);
    await _saveGalleryViewPreferences();
  }

  Future<void> resetGalleryStyle() async {
    state = state.copyWith(
      galleryGridSpacing: GalleryStyleLevel.standard,
      galleryCornerRadius: GalleryStyleLevel.standard,
    );
    await _saveGalleryViewPreferences();
  }

  Future<void> increaseGalleryItemExtent() => _setGalleryItemExtent(
    GalleryItemExtent.increase(state.galleryItemExtent),
  );

  Future<void> decreaseGalleryItemExtent() => _setGalleryItemExtent(
    GalleryItemExtent.decrease(state.galleryItemExtent),
  );

  Future<void> _setGalleryItemExtent(double itemExtent) async {
    if (itemExtent == state.galleryItemExtent) return;
    state = state.copyWith(galleryItemExtent: itemExtent);
    await _saveGalleryViewPreferences();
  }

  Future<void> _saveGalleryViewPreferences() {
    return ref.read(saveGalleryViewPreferencesProvider)(
      GalleryViewPreferences(
        showItemNames: state.showItemNames,
        layoutMode: state.galleryLayoutMode,
        itemExtent: state.galleryItemExtent,
        sort: state.gallerySort,
        gridSpacing: state.galleryGridSpacing,
        cornerRadius: state.galleryCornerRadius,
      ),
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
