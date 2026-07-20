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
}
