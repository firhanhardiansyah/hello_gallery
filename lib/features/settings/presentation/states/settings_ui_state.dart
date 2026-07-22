import '../../domain/value_objects/app_appearance_mode.dart';
import '../../domain/value_objects/app_color_theme.dart';

class SettingsUiState {
  const SettingsUiState({
    this.rootPath,
    this.isLoading = true,
    this.appearanceMode = AppAppearanceMode.system,
    this.colorTheme = AppColorTheme.indigo,
    this.showItemNames = true,
  });

  final String? rootPath;
  final bool isLoading;
  final AppAppearanceMode appearanceMode;
  final AppColorTheme colorTheme;
  final bool showItemNames;

  SettingsUiState copyWith({
    String? rootPath,
    bool? isLoading,
    AppAppearanceMode? appearanceMode,
    AppColorTheme? colorTheme,
    bool? showItemNames,
  }) => SettingsUiState(
    rootPath: rootPath ?? this.rootPath,
    isLoading: isLoading ?? this.isLoading,
    appearanceMode: appearanceMode ?? this.appearanceMode,
    colorTheme: colorTheme ?? this.colorTheme,
    showItemNames: showItemNames ?? this.showItemNames,
  );
}
