import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import '../features/settings/domain/value_objects/app_appearance_mode.dart';
import '../features/settings/presentation/notifiers/settings_notifier.dart';

class HelloGalleryApp extends ConsumerWidget {
  const HelloGalleryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    return MaterialApp.router(
      title: 'Hello Gallery',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        colorTheme: settings.colorTheme,
        brightness: Brightness.light,
      ),
      darkTheme: buildAppTheme(
        colorTheme: settings.colorTheme,
        brightness: Brightness.dark,
      ),
      themeMode: switch (settings.appearanceMode) {
        AppAppearanceMode.system => ThemeMode.system,
        AppAppearanceMode.light => ThemeMode.light,
        AppAppearanceMode.dark => ThemeMode.dark,
      },
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
