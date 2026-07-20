import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../settings/domain/value_objects/app_appearance_mode.dart';
import '../../../../settings/domain/value_objects/app_color_theme.dart';
import '../../../../settings/presentation/notifiers/settings_notifier.dart';

enum _ThemeMenuOption {
  systemMode,
  lightMode,
  darkMode,
  indigoTheme,
  pinkTheme,
  emeraldTheme,
}

class AppearanceThemeMenu extends ConsumerWidget {
  const AppearanceThemeMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    return PopupMenuButton<_ThemeMenuOption>(
      tooltip: 'Appearance and theme',
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedPaintBoard),
      onSelected: (option) {
        final notifier = ref.read(settingsNotifierProvider.notifier);
        switch (option) {
          case _ThemeMenuOption.systemMode:
            unawaited(notifier.setAppearanceMode(AppAppearanceMode.system));
          case _ThemeMenuOption.lightMode:
            unawaited(notifier.setAppearanceMode(AppAppearanceMode.light));
          case _ThemeMenuOption.darkMode:
            unawaited(notifier.setAppearanceMode(AppAppearanceMode.dark));
          case _ThemeMenuOption.indigoTheme:
            unawaited(notifier.setColorTheme(AppColorTheme.indigo));
          case _ThemeMenuOption.pinkTheme:
            unawaited(notifier.setColorTheme(AppColorTheme.pink));
          case _ThemeMenuOption.emeraldTheme:
            unawaited(notifier.setColorTheme(AppColorTheme.emerald));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<_ThemeMenuOption>(
          enabled: false,
          height: 32,
          child: Text('Mode'),
        ),
        _item(
          option: _ThemeMenuOption.systemMode,
          label: 'System',
          icon: HugeIcons.strokeRoundedComputer,
          selected: settings.appearanceMode == AppAppearanceMode.system,
        ),
        _item(
          option: _ThemeMenuOption.lightMode,
          label: 'Light',
          icon: HugeIcons.strokeRoundedSun01,
          selected: settings.appearanceMode == AppAppearanceMode.light,
        ),
        _item(
          option: _ThemeMenuOption.darkMode,
          label: 'Dark',
          icon: HugeIcons.strokeRoundedMoon02,
          selected: settings.appearanceMode == AppAppearanceMode.dark,
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_ThemeMenuOption>(
          enabled: false,
          height: 32,
          child: Text('Color theme'),
        ),
        _item(
          option: _ThemeMenuOption.indigoTheme,
          label: 'Indigo',
          icon: HugeIcons.strokeRoundedColors,
          iconColor: AppColorTokens.indigoSeed,
          selected: settings.colorTheme == AppColorTheme.indigo,
        ),
        _item(
          option: _ThemeMenuOption.pinkTheme,
          label: 'Pink',
          icon: HugeIcons.strokeRoundedColors,
          iconColor: AppColorTokens.pinkSeed,
          selected: settings.colorTheme == AppColorTheme.pink,
        ),
        _item(
          option: _ThemeMenuOption.emeraldTheme,
          label: 'Emerald',
          icon: HugeIcons.strokeRoundedColors,
          iconColor: AppColorTokens.emeraldSeed,
          selected: settings.colorTheme == AppColorTheme.emerald,
        ),
      ],
    );
  }

  PopupMenuItem<_ThemeMenuOption> _item({
    required _ThemeMenuOption option,
    required String label,
    required List<List<dynamic>> icon,
    required bool selected,
    Color? iconColor,
  }) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 20, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label)),
          if (selected)
            const HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 18),
        ],
      ),
    );
  }
}
