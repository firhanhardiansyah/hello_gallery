import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF6C63FF);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF17171C),
    ),
    scaffoldBackgroundColor: const Color(0xFF101014),
    cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    useMaterial3: true,
  );
}
