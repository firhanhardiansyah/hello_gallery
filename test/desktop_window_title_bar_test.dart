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
