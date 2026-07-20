enum AppColorTheme {
  indigo,
  pink,
  emerald;

  static AppColorTheme fromStorage(String? value) {
    if (value == 'blue') return emerald;
    return values.where((theme) => theme.name == value).firstOrNull ?? indigo;
  }
}
