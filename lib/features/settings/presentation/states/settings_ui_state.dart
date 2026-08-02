import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/value_objects/app_appearance_mode.dart';
import '../../domain/value_objects/app_color_theme.dart';
import '../../../gallery/domain/value_objects/gallery_item_extent.dart';
import '../../../gallery/domain/value_objects/gallery_layout_mode.dart';

part 'settings_ui_state.freezed.dart';

@freezed
sealed class SettingsLoadState with _$SettingsLoadState {
  const factory SettingsLoadState.loading() = SettingsLoading;
  const factory SettingsLoadState.rootRequired() = SettingsRootRequired;
  const factory SettingsLoadState.ready(String rootPath) = SettingsReady;
  const factory SettingsLoadState.error(String message) = SettingsError;
}

@freezed
abstract class SettingsUiState with _$SettingsUiState {
  const SettingsUiState._();

  const factory SettingsUiState({
    @Default(SettingsLoadState.loading()) SettingsLoadState loadState,
    @Default(AppAppearanceMode.system) AppAppearanceMode appearanceMode,
    @Default(AppColorTheme.indigo) AppColorTheme colorTheme,
    @Default(true) bool showItemNames,
    @Default(GalleryLayoutMode.grid) GalleryLayoutMode galleryLayoutMode,
    @Default(GalleryItemExtent.defaultValue) double galleryItemExtent,
  }) = _SettingsUiState;

  String? get rootPath => switch (loadState) {
    SettingsReady(:final rootPath) => rootPath,
    SettingsLoading() || SettingsRootRequired() || SettingsError() => null,
  };
}
