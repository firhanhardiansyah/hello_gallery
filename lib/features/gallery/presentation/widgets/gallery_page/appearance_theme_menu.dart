import 'dart:async';

import 'package:flex_color_picker/flex_color_picker.dart';
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
  customTheme,
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
          case _ThemeMenuOption.customTheme:
            unawaited(_pickCustomColor(context, notifier, settings.colorTheme));
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
        PopupMenuDivider(indent: AppSpacing.md, endIndent: AppSpacing.md),
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
        _item(
          option: _ThemeMenuOption.customTheme,
          label: 'Custom…',
          icon: HugeIcons.strokeRoundedColors,
          iconColor: Color(
            settings.colorTheme.customColorValue ??
                AppColorTheme.defaultCustomColorValue,
          ),
          selected: settings.colorTheme.isCustom,
        ),
      ],
    );
  }

  Future<void> _pickCustomColor(
    BuildContext context,
    SettingsNotifier notifier,
    AppColorTheme previousColorTheme,
  ) async {
    final initialTheme = await notifier.readCustomColorTheme();
    if (!context.mounted) return;
    var selectedColor = Color(initialTheme.customColorValue!);
    var useExactColor = initialTheme.useExactColor;

    void previewTheme() {
      notifier.previewColorTheme(
        AppColorTheme.custom(
          selectedColor.toARGB32(),
          useExactColor: useExactColor,
        ),
      );
    }

    final accepted =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              title: const Center(child: Text('Custom color theme')),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ColorPicker(
                        color: selectedColor,
                        onColorChanged: (color) {
                          selectedColor = color;
                          previewTheme();
                        },
                        pickersEnabled: const {
                          ColorPickerType.primary: false,
                          ColorPickerType.accent: false,
                          ColorPickerType.wheel: true,
                        },
                        enableShadesSelection: false,
                        enableOpacity: false,
                        showColorCode: true,
                        colorCodeHasColor: true,
                        mainAxisSize: MainAxisSize.min,
                        wheelDiameter: 220,
                      ),
                      CheckboxListTile(
                        value: useExactColor,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Use exact HEX color'),
                        subtitle: const Text(
                          'Keep this color as the theme primary color.',
                        ),
                        onChanged: (value) {
                          setDialogState(() => useExactColor = value ?? false);
                          previewTheme();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (!context.mounted) return;
    if (!accepted) {
      notifier.previewColorTheme(previousColorTheme);
      return;
    }
    await notifier.setCustomColorTheme(
      selectedColor.toARGB32(),
      useExactColor: useExactColor,
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
