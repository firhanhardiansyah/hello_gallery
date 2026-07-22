import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/core/widgets/desktop_window_title_bar.dart';

void main() {
  testWidgets('reserves native window button space on macOS', (tester) async {
    await _pumpTitleBar(
      tester,
      platform: DesktopWindowPlatform.macOS,
      reserveMacOSWindowButtons: true,
    );

    expect(
      tester.getRect(find.byKey(const ValueKey('title-content'))).left,
      DesktopWindowTitleBar.macOSWindowButtonsInset,
    );
    expect(find.byKey(const ValueKey('test-caption-controls')), findsNothing);
    expect(
      tester.getSize(find.byType(DesktopWindowTitleBar)).height,
      DesktopWindowTitleBar.macOSHeight,
    );
  });

  testWidgets('adds caption controls to the right on Windows', (tester) async {
    await _pumpTitleBar(
      tester,
      platform: DesktopWindowPlatform.windows,
      reserveMacOSWindowButtons: true,
    );

    final content = tester.getRect(find.byKey(const ValueKey('title-content')));
    final controls = tester.getRect(
      find.byKey(const ValueKey('test-caption-controls')),
    );
    expect(content.left, 0);
    expect(content.right, controls.left);
    expect(controls.right, 500);
    expect(
      tester.getSize(find.byType(DesktopWindowTitleBar)).height,
      DesktopWindowTitleBar.height,
    );
    expect(
      find.descendant(
        of: find.byType(DesktopDragToMoveArea),
        matching: find.byKey(const ValueKey('title-content')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DesktopDragToMoveArea),
        matching: find.byKey(const ValueKey('test-caption-controls')),
      ),
      findsNothing,
    );
  });

  testWidgets('uses standard desktop action buttons on macOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 500,
            child: DesktopWindowTitleBar(
              platform: DesktopWindowPlatform.macOS,
              backgroundColor: Colors.white,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  key: const ValueKey('macos-title-action'),
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('macos-title-action'))),
      const Size.square(48),
    );
  });
}

Future<void> _pumpTitleBar(
  WidgetTester tester, {
  required DesktopWindowPlatform platform,
  required bool reserveMacOSWindowButtons,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 500,
          child: DesktopWindowTitleBar(
            platform: platform,
            reserveMacOSWindowButtons: reserveMacOSWindowButtons,
            backgroundColor: Colors.white,
            windowsCaptionControls: const SizedBox(
              key: ValueKey('test-caption-controls'),
              width: 138,
            ),
            child: const SizedBox.expand(key: ValueKey('title-content')),
          ),
        ),
      ),
    ),
  );
}
