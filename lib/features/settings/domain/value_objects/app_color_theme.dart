final class AppColorTheme {
  const AppColorTheme._(
    this.name, {
    this.customColorValue,
    this.useExactColor = false,
  });

  static const defaultCustomColorValue = 0xFF6366F1;
  static const indigo = AppColorTheme._('indigo');
  static const pink = AppColorTheme._('pink');
  static const emerald = AppColorTheme._('emerald');

  factory AppColorTheme.custom(int colorValue, {bool useExactColor = false}) =>
      AppColorTheme._(
        'custom',
        customColorValue: colorValue | 0xFF000000,
        useExactColor: useExactColor,
      );

  final String name;
  final int? customColorValue;
  final bool useExactColor;

  bool get isCustom => name == 'custom';

  static AppColorTheme fromStorage(
    String? value, {
    int? customColorValue,
    bool useExactColor = false,
  }) => switch (value) {
    'pink' => pink,
    'emerald' || 'blue' => emerald,
    'custom' => AppColorTheme.custom(
      customColorValue ?? defaultCustomColorValue,
      useExactColor: useExactColor,
    ),
    _ => indigo,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppColorTheme &&
          other.name == name &&
          other.customColorValue == customColorValue &&
          other.useExactColor == useExactColor;

  @override
  int get hashCode => Object.hash(name, customColorValue, useExactColor);

  @override
  String toString() => isCustom
      ? 'AppColorTheme.custom(0x${customColorValue!.toRadixString(16).toUpperCase()})'
      : 'AppColorTheme.$name';
}
