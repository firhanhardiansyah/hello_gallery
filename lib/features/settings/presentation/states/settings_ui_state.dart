import '../../domain/value_objects/app_appearance_mode.dart';
import '../../domain/value_objects/app_color_theme.dart';

class SettingsUiState {
  const SettingsUiState({
    this.rootPath,
    this.isLoading = true,
    this.appearanceMode = AppAppearanceMode.system,
    this.colorTheme = AppColorTheme.indigo,
  });

  final String? rootPath;
  final bool isLoading;
  final AppAppearanceMode appearanceMode;
  final AppColorTheme colorTheme;

  SettingsUiState copyWith({
    String? rootPath,
    bool? isLoading,
    AppAppearanceMode? appearanceMode,
    AppColorTheme? colorTheme,
  }) => SettingsUiState(
    rootPath: rootPath ?? this.rootPath,
    isLoading: isLoading ?? this.isLoading,
    appearanceMode: appearanceMode ?? this.appearanceMode,
    colorTheme: colorTheme ?? this.colorTheme,
  );
}
