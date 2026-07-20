class SettingsUiState {
  const SettingsUiState({this.rootPath, this.isLoading = true});

  final String? rootPath;
  final bool isLoading;

  SettingsUiState copyWith({String? rootPath, bool? isLoading}) =>
      SettingsUiState(
        rootPath: rootPath ?? this.rootPath,
        isLoading: isLoading ?? this.isLoading,
      );
}
