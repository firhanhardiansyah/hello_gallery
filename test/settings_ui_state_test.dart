import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_layout_mode.dart';
import 'package:hello_gallery/features/settings/presentation/states/settings_ui_state.dart';

void main() {
  test('defaults to loading while preserving default preferences', () {
    const state = SettingsUiState();

    expect(state.loadState, const SettingsLoadState.loading());
    expect(state.rootPath, isNull);
    expect(state.colorTheme, AppColorTheme.indigo);
    expect(state.showItemNames, isTrue);
    expect(state.galleryLayoutMode, GalleryLayoutMode.grid);
  });

  test('exposes a non-null root only from the ready state', () {
    const ready = SettingsUiState(
      loadState: SettingsLoadState.ready('/gallery'),
    );
    const rootRequired = SettingsUiState(
      loadState: SettingsLoadState.rootRequired(),
    );

    expect(ready.rootPath, '/gallery');
    expect(rootRequired.rootPath, isNull);
  });

  test('renders every lifecycle through when', () {
    String describe(SettingsLoadState state) => state.when(
      loading: () => 'loading',
      rootRequired: () => 'root required',
      ready: (rootPath) => 'ready: $rootPath',
      error: (message) => 'error: $message',
    );

    expect(describe(const SettingsLoadState.loading()), 'loading');
    expect(describe(const SettingsLoadState.rootRequired()), 'root required');
    expect(
      describe(const SettingsLoadState.ready('/gallery')),
      'ready: /gallery',
    );
    expect(
      describe(const SettingsLoadState.error('Unavailable')),
      'error: Unavailable',
    );
  });
}
