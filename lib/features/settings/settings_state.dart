class SettingsState {
  const SettingsState({this.rootPath, this.isLoading = true});

  final String? rootPath;
  final bool isLoading;

  SettingsState copyWith({String? rootPath, bool? isLoading}) => SettingsState(
    rootPath: rootPath ?? this.rootPath,
    isLoading: isLoading ?? this.isLoading,
  );
}
