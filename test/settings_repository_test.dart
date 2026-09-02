import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:hello_gallery/features/settings/domain/entities/gallery_view_preferences.dart';
import 'package:hello_gallery/features/settings/domain/entities/theme_preferences.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_appearance_mode.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_item_extent.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_layout_mode.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_style_level.dart';
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

  test('custom color theme restores its saved color', () async {
    SharedPreferences.setMockInitialValues({
      'color_theme': 'custom',
      'custom_color_theme_value': 0xFF2A9D8F,
      'custom_color_theme_use_exact': true,
    });
    final repository = SettingsRepositoryImpl();

    expect(
      await repository.readColorTheme(),
      AppColorTheme.custom(0xFF2A9D8F, useExactColor: true),
    );
  });

  test(
    'last custom color remains available after selecting a preset',
    () async {
      final repository = SettingsRepositoryImpl();

      await repository.saveThemePreferences(
        ThemePreferences(
          colorTheme: AppColorTheme.custom(0xFFE76F51, useExactColor: true),
        ),
      );
      await repository.saveThemePreferences(
        const ThemePreferences(colorTheme: AppColorTheme.emerald),
      );

      expect(await repository.readColorTheme(), AppColorTheme.emerald);
      expect(
        await repository.readCustomColorTheme(),
        AppColorTheme.custom(0xFFE76F51, useExactColor: true),
      );
    },
  );

  test('gallery view preferences show item names by default', () async {
    final repository = SettingsRepositoryImpl();

    final preferences = await repository.readGalleryViewPreferences();

    expect(preferences.showItemNames, isTrue);
    expect(preferences.layoutMode, GalleryLayoutMode.grid);
    expect(preferences.itemExtent, GalleryItemExtent.defaultValue);
    expect(preferences.sort, GallerySort.nameAscending);
    expect(preferences.gridSpacing, GalleryStyleLevel.standard);
    expect(preferences.cornerRadius, GalleryStyleLevel.standard);
    expect(preferences.mediaPreviewFilmstripEnabled, isTrue);
  });

  test('gallery view preferences persist display options', () async {
    final repository = SettingsRepositoryImpl();

    await repository.saveGalleryViewPreferences(
      const GalleryViewPreferences(
        showItemNames: false,
        layoutMode: GalleryLayoutMode.quilted,
        itemExtent: 400,
        sort: GallerySort.newest,
        gridSpacing: GalleryStyleLevel.none,
        cornerRadius: GalleryStyleLevel.xl,
        mediaPreviewFilmstripEnabled: false,
      ),
    );

    final preferences = await repository.readGalleryViewPreferences();
    expect(preferences.showItemNames, isFalse);
    expect(preferences.layoutMode, GalleryLayoutMode.quilted);
    expect(preferences.itemExtent, 400);
    expect(preferences.sort, GallerySort.newest);
    expect(preferences.gridSpacing, GalleryStyleLevel.none);
    expect(preferences.cornerRadius, GalleryStyleLevel.xl);
    expect(preferences.mediaPreviewFilmstripEnabled, isFalse);
  });

  test('masonry gallery layout can be restored from storage', () async {
    SharedPreferences.setMockInitialValues({'gallery_layout_mode': 'masonry'});

    final preferences = await SettingsRepositoryImpl()
        .readGalleryViewPreferences();

    expect(preferences.layoutMode, GalleryLayoutMode.masonry);
  });

  test('aspect ratio grid layout can be restored from storage', () async {
    SharedPreferences.setMockInitialValues({
      'gallery_layout_mode': 'aspectRatioGrid',
    });

    final preferences = await SettingsRepositoryImpl()
        .readGalleryViewPreferences();

    expect(preferences.layoutMode, GalleryLayoutMode.aspectRatioGrid);
  });

  test('unknown gallery sort falls back to name ascending', () async {
    SharedPreferences.setMockInitialValues({'gallery_sort': 'unsupported'});

    final preferences = await SettingsRepositoryImpl()
        .readGalleryViewPreferences();

    expect(preferences.sort, GallerySort.nameAscending);
  });

  test('unknown gallery style levels fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'gallery_grid_spacing': 'unsupported',
      'gallery_corner_radius': 'unsupported',
    });

    final preferences = await SettingsRepositoryImpl()
        .readGalleryViewPreferences();

    expect(preferences.gridSpacing, GalleryStyleLevel.standard);
    expect(preferences.cornerRadius, GalleryStyleLevel.standard);
  });
}
