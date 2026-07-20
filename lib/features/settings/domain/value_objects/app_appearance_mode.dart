enum AppAppearanceMode {
  system,
  light,
  dark;

  static AppAppearanceMode fromStorage(String? value) {
    return values.where((mode) => mode.name == value).firstOrNull ?? system;
  }
}
