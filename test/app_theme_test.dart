import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  test('light theme exposes light semantic color tokens', () {
    final theme = buildAppTheme(
      colorTheme: AppColorTheme.indigo,
      brightness: Brightness.light,
    );

    expect(
      theme.scaffoldBackgroundColor,
      AppColorTokens.light.scaffoldBackground,
    );
    expect(theme.colorScheme.surface, AppColorTokens.light.surface);
    expect(theme.extension<AppColorTokens>(), AppColorTokens.light);
  });

  test('dark theme exposes dark semantic color tokens', () {
    final theme = buildAppTheme(
      colorTheme: AppColorTheme.indigo,
      brightness: Brightness.dark,
    );

    expect(
      theme.scaffoldBackgroundColor,
      AppColorTokens.dark.scaffoldBackground,
    );
    expect(theme.colorScheme.surface, AppColorTokens.dark.surface);
    expect(theme.extension<AppColorTokens>(), AppColorTokens.dark);
  });

  test(
    'custom color theme builds its color scheme from the selected color',
    () {
      const customColor = Color(0xFFF4D35E);

      final tonalTheme = buildAppTheme(
        colorTheme: AppColorTheme.custom(customColor.toARGB32()),
        brightness: Brightness.light,
      );

      final theme = buildAppTheme(
        colorTheme: AppColorTheme.custom(
          customColor.toARGB32(),
          useExactColor: true,
        ),
        brightness: Brightness.light,
      );

      expect(
        tonalTheme.colorScheme.surfaceContainerHigh,
        ColorScheme.fromSeed(seedColor: customColor).surfaceContainerHigh,
      );
      expect(
        tonalTheme.colorScheme.surface,
        ColorScheme.fromSeed(seedColor: customColor).surfaceContainerLow,
      );
      expect(theme.colorScheme.primary, customColor);
      expect(theme.colorScheme.surfaceContainerHigh, customColor);
      expect(
        theme.colorScheme.surface,
        Color.lerp(customColor, Colors.white, 0.12),
      );
      expect(theme.colorScheme.onPrimary, Colors.black);
      expect(theme.colorScheme.onSurface, Colors.black);
      expect(theme.iconTheme.color, Colors.black);
      expect(
        theme.popupMenuTheme.color,
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(theme.popupMenuTheme.iconColor, Colors.black);
      expect(theme.popupMenuTheme.textStyle?.color, Colors.black);
      expect(theme.sliderTheme.activeTrackColor, customColor);
      expect(theme.sliderTheme.thumbColor, customColor);
    },
  );

  test('exact dark custom color uses a lighter foreground', () {
    const customColor = Color(0xFF1B263B);

    final theme = buildAppTheme(
      colorTheme: AppColorTheme.custom(
        customColor.toARGB32(),
        useExactColor: true,
      ),
      brightness: Brightness.dark,
    );

    expect(
      theme.colorScheme.surface,
      Color.lerp(customColor, Colors.black, 0.12),
    );
    expect(theme.colorScheme.onPrimary, Colors.white);
    expect(theme.colorScheme.onSurface, Colors.white);
    expect(theme.iconTheme.color, Colors.white);
    expect(theme.popupMenuTheme.iconColor, Colors.white);
    expect(theme.popupMenuTheme.textStyle?.color, Colors.white);
  });
}
