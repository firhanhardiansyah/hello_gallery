import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/preview_shell_top_bar_overlay.dart';

void main() {
  testWidgets('animates and blocks interaction while the top bar is hidden', (
    tester,
  ) async {
    var tapCount = 0;

    Widget buildOverlay({required bool visible}) {
      return MaterialApp(
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
