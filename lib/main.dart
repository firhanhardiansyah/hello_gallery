import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/window/desktop_window_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await windowManager.ensureInitialized();
  final usesIntegratedTitleBar = Platform.isMacOS || Platform.isWindows;
  unawaited(
    windowManager.waitUntilReadyToShow(
      WindowOptions(
        minimumSize: DesktopWindowConfig.minimumSize,
        titleBarStyle: usesIntegratedTitleBar
            ? TitleBarStyle.hidden
            : TitleBarStyle.normal,
        windowButtonVisibility: Platform.isMacOS,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    ),
  );
  runApp(const ProviderScope(child: HelloGalleryApp()));
}
