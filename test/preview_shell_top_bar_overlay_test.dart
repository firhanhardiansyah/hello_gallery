import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/preview_shell_top_bar_overlay.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('animates and blocks interaction while the top bar is hidden', (
    tester,
  ) async {
    var tapCount = 0;

    Widget buildOverlay({required bool visible}) {
      return MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: Stack(
            children: [
              PreviewShellTopBarOverlay(
                visible: visible,
                child: SizedBox(
                  height: 56,
                  child: TextButton(
                    onPressed: () => tapCount++,
                    child: const Text('Top bar action'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildOverlay(visible: true));
    final gradientDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('preview-shell-top-bar-gradient')),
                )
                .decoration
            as BoxDecoration;
    expect(gradientDecoration.gradient, isA<LinearGradient>());
    await tester.tap(find.text('Top bar action'));
    expect(tapCount, 1);

    await tester.pumpWidget(buildOverlay(visible: false));
    await tester.pumpAndSettle();

    final opacity = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('preview-shell-top-bar-opacity')),
    );
    final ignorePointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('preview-shell-top-bar-pointer')),
    );
    expect(opacity.opacity, 0);
    expect(ignorePointer.ignoring, isTrue);
  });

  testWidgets('stays visible while the pointer hovers over the top bar', (
    tester,
  ) async {
    var visible = true;

    Widget buildOverlay() {
      return MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: Stack(
            children: [
              PreviewShellTopBarOverlay(
                visible: visible,
                child: const SizedBox(height: 56, child: Text('Top bar')),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildOverlay());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Top bar')));
    await tester.pump();

    visible = false;
    await tester.pumpWidget(buildOverlay());
    await tester.pumpAndSettle();

    AnimatedOpacity opacity() => tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('preview-shell-top-bar-opacity')),
    );
    expect(opacity().opacity, 1);

    await mouse.moveTo(const Offset(200, 200));
    await tester.pumpAndSettle();

    expect(opacity().opacity, 0);
  });
}
