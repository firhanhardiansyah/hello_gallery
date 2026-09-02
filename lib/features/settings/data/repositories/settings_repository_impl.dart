import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/gallery_view_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/theme_preferences.dart';
import '../../domain/value_objects/app_appearance_mode.dart';
import '../../domain/value_objects/app_color_theme.dart';
import '../../../gallery/domain/value_objects/gallery_item_extent.dart';
import '../../../gallery/domain/value_objects/gallery_layout_mode.dart';
import '../../../gallery/domain/value_objects/gallery_sort.dart';
import '../../../gallery/domain/value_objects/gallery_style_level.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  static const _rootPathKey = 'gallery_root_path';
  static const _rootBookmarkKey = 'gallery_root_bookmark';
  static const _appearanceModeKey = 'appearance_mode';
  static const _colorThemeKey = 'color_theme';
  static const _customColorThemeValueKey = 'custom_color_theme_value';
  static const _customColorThemeUseExactKey = 'custom_color_theme_use_exact';
  static const _showItemNamesKey = 'show_item_names';
  static const _galleryLayoutModeKey = 'gallery_layout_mode';
  static const _galleryItemExtentKey = 'gallery_item_extent';
  static const _gallerySortKey = 'gallery_sort';
  static const _galleryGridSpacingKey = 'gallery_grid_spacing';
  static const _galleryCornerRadiusKey = 'gallery_corner_radius';
  static const _mediaPreviewFilmstripEnabledKey =
      'media_preview_filmstrip_enabled';

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
    return AppColorTheme.fromStorage(
      preferences.getString(_colorThemeKey),
      customColorValue: preferences.getInt(_customColorThemeValueKey),
      useExactColor: preferences.getBool(_customColorThemeUseExactKey) ?? false,
    );
  }

  @override
  Future<AppColorTheme> readCustomColorTheme() async {
    final preferences = await SharedPreferences.getInstance();
    return AppColorTheme.custom(
      preferences.getInt(_customColorThemeValueKey) ??
          AppColorTheme.defaultCustomColorValue,
      useExactColor: preferences.getBool(_customColorThemeUseExactKey) ?? false,
    );
  }

  @override
  Future<void> saveThemePreferences(ThemePreferences preferences) async {
    final storage = await SharedPreferences.getInstance();
    final writes = <Future<bool>>[
      storage.setString(_appearanceModeKey, preferences.appearanceMode.name),
      storage.setString(_colorThemeKey, preferences.colorTheme.name),
    ];
    final customColorValue = preferences.colorTheme.customColorValue;
    if (customColorValue != null) {
      writes.add(storage.setInt(_customColorThemeValueKey, customColorValue));
      writes.add(
        storage.setBool(
          _customColorThemeUseExactKey,
          preferences.colorTheme.useExactColor,
        ),
      );
    }
    await Future.wait(writes);
  }

  @override
  Future<GalleryViewPreferences> readGalleryViewPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return GalleryViewPreferences(
      showItemNames: preferences.getBool(_showItemNamesKey) ?? true,
      layoutMode: GalleryLayoutMode.fromStorage(
        preferences.getString(_galleryLayoutModeKey),
      ),
      itemExtent: GalleryItemExtent.normalize(
        preferences.getDouble(_galleryItemExtentKey),
      ),
      sort: GallerySort.fromStorage(preferences.getString(_gallerySortKey)),
      gridSpacing: GalleryStyleLevel.fromStorage(
        preferences.getString(_galleryGridSpacingKey),
      ),
      cornerRadius: GalleryStyleLevel.fromStorage(
        preferences.getString(_galleryCornerRadiusKey),
      ),
      mediaPreviewFilmstripEnabled:
          preferences.getBool(_mediaPreviewFilmstripEnabledKey) ?? true,
    );
  }

  @override
  Future<void> saveGalleryViewPreferences(
    GalleryViewPreferences preferences,
  ) async {
    final storage = await SharedPreferences.getInstance();
    await Future.wait([
      storage.setBool(_showItemNamesKey, preferences.showItemNames),
      storage.setString(_galleryLayoutModeKey, preferences.layoutMode.name),
      storage.setDouble(_galleryItemExtentKey, preferences.itemExtent),
      storage.setString(_gallerySortKey, preferences.sort.name),
      storage.setString(_galleryGridSpacingKey, preferences.gridSpacing.name),
      storage.setString(_galleryCornerRadiusKey, preferences.cornerRadius.name),
      storage.setBool(
        _mediaPreviewFilmstripEnabledKey,
        preferences.mediaPreviewFilmstripEnabled,
      ),
    ]);
  }
}
