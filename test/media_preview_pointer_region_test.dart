import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/media_preview_pointer_region.dart';

void main() {
  testWidgets('hides after pointer exits and cancels when it returns', (
    tester,
  ) async {
    var activityCount = 0;
    var exitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.square(
            dimension: 200,
            child: MediaPreviewPointerRegion(
              exitDelay: const Duration(milliseconds: 300),
              onActivity: () => activityCount++,
              onExitIdle: () => exitCount++,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(300, 300));
    await mouse.moveTo(const Offset(100, 100));
    await tester.pump();
    expect(activityCount, greaterThan(0));

    await mouse.moveTo(const Offset(300, 300));
    await tester.pump(const Duration(milliseconds: 200));
    await mouse.moveTo(const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(exitCount, 0);

    await mouse.moveTo(const Offset(300, 300));
    await tester.pump(const Duration(milliseconds: 299));
    expect(exitCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(exitCount, 1);
  });
}
