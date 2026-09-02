import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

import '../../core/theme/app_color_tokens.dart';
import '../../features/settings/domain/value_objects/app_color_theme.dart';

ThemeData buildAppTheme({
  required AppColorTheme colorTheme,
  required Brightness brightness,
}) {
  final customColorValue = colorTheme.customColorValue;
  final seed = customColorValue != null
      ? Color(customColorValue)
      : switch (colorTheme.name) {
          'pink' => AppColorTokens.pinkSeed,
          'emerald' => AppColorTokens.emeraldSeed,
          _ => AppColorTokens.indigoSeed,
        };
  final tokens = brightness == Brightness.dark
      ? AppColorTokens.dark
      : AppColorTokens.light;
  final generatedColorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  var colorScheme = generatedColorScheme.copyWith(surface: tokens.surface);
  if (colorTheme.isCustom) {
    colorScheme = generatedColorScheme.copyWith(
      surface: generatedColorScheme.surfaceContainerLow,
    );
  }
  if (colorTheme.isCustom && colorTheme.useExactColor) {
    final bodySurface = Color.lerp(
      seed,
      brightness == Brightness.light ? Colors.white : Colors.black,
      0.12,
    )!;
    final elevatedSurface = Color.lerp(
      seed,
      brightness == Brightness.light ? Colors.black : Colors.white,
      0.08,
    )!;
    final foreground = _contrastingForeground(bodySurface);
    colorScheme = generatedColorScheme.copyWith(
      primary: seed,
      onPrimary: _contrastingForeground(seed),
      surface: bodySurface,
      onSurface: foreground,
      onSurfaceVariant: Color.lerp(bodySurface, foreground, 0.72),
      surfaceContainerLow: bodySurface,
      surfaceContainerHigh: seed,
      surfaceContainerHighest: elevatedSurface,
    );
  }
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.scaffoldBackground,
    cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    iconTheme: IconThemeData(color: colorScheme.onSurface),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerHighest,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: colorScheme.onSurface),
      iconColor: colorScheme.onSurface,
    ),
    extensions: [tokens],
    useMaterial3: true,
    sliderTheme: SliderThemeData(
      trackHeight: 2,
      activeTrackColor: seed,
      inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.24),
      thumbColor: seed,
      overlayColor: seed.withValues(alpha: 0.12),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    ),
  );
}

Color _contrastingForeground(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
