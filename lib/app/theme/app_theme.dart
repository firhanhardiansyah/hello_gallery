import 'package:flutter/material.dart';

import '../../core/theme/app_color_tokens.dart';
import '../../features/settings/domain/value_objects/app_color_theme.dart';

ThemeData buildAppTheme({
  required AppColorTheme colorTheme,
  required Brightness brightness,
}) {
  final seed = switch (colorTheme) {
    AppColorTheme.indigo => AppColorTokens.indigoSeed,
    AppColorTheme.pink => AppColorTokens.pinkSeed,
    AppColorTheme.emerald => AppColorTokens.emeraldSeed,
  };
  final tokens = brightness == Brightness.dark
      ? AppColorTokens.dark
      : AppColorTokens.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(surface: tokens.surface);
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.scaffoldBackground,
    cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    extensions: [tokens],
    useMaterial3: true,
  );
}
