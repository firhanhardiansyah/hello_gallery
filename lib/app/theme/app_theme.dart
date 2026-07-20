import 'package:flutter/material.dart';

import '../../features/settings/domain/value_objects/app_color_theme.dart';

ThemeData buildAppTheme({
  required AppColorTheme colorTheme,
  required Brightness brightness,
}) {
  final seed = switch (colorTheme) {
    AppColorTheme.indigo => const Color(0xFF6366F1),
    AppColorTheme.pink => const Color(0xFFEC4899),
    AppColorTheme.emerald => const Color(0xFF00897B),
  };
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    colorScheme: isDark
        ? colorScheme.copyWith(surface: const Color(0xFF17171C))
        : colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101014)
        : colorScheme.surface,
    cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    useMaterial3: true,
  );
}
