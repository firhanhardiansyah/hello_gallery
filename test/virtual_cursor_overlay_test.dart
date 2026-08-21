import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/gamepad/presentation/widgets/virtual_cursor_overlay.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/media_preview_pointer_region.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('lets preview controls hide after gamepad cursor is idle', (
    tester,
  ) async {
    final events = StreamController<NormalizedGamepadEvent>.broadcast(
      sync: true,
    );
    addTearDown(events.close);
    var enterCount = 0;
    var hideCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.light,
        ),
        home: SizedBox.square(
          dimension: 300,
          child: VirtualCursorOverlay(
            gamepadEvents: events.stream,
            idleTimeout: const Duration(milliseconds: 50),
            child: MediaPreviewPointerRegion(
              exitDelay: const Duration(milliseconds: 20),
              onActivity: () => enterCount++,
              onExitIdle: () => hideCount++,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

    events.add(_gamepadAxis(GamepadAxis.rightStickX, value: 1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(enterCount, greaterThan(0));

    events.add(_gamepadAxis(GamepadAxis.rightStickX, value: 0));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 20));

    expect(hideCount, 1);
  });

  testWidgets('can suppress the gamepad cursor for clean preview', (
    tester,
  ) async {
    final events = StreamController<NormalizedGamepadEvent>.broadcast(
      sync: true,
    );
    addTearDown(events.close);
    var showCursor = true;

    Widget buildOverlay() => MaterialApp(
      theme: buildAppTheme(
        colorTheme: AppColorTheme.indigo,
        brightness: Brightness.light,
      ),
      home: SizedBox.square(
        dimension: 300,
        child: VirtualCursorOverlay(
          gamepadEvents: events.stream,
          showCursor: showCursor,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    );

    await tester.pumpWidget(buildOverlay());
    events.add(_gamepadAxis(GamepadAxis.rightStickX, value: 1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('virtual-cursor-indicator')), findsOne);

    showCursor = false;
    await tester.pumpWidget(buildOverlay());
    expect(
      find.byKey(const ValueKey('virtual-cursor-indicator')),
      findsNothing,
    );
  });
}

NormalizedGamepadEvent _gamepadAxis(GamepadAxis axis, {required double value}) {
  final rawEvent = GamepadEvent(
    gamepadId: 'test-controller',
    timestamp: 0,
    type: KeyType.analog,
    key: axis.name,
    value: value,
  );
  return NormalizedGamepadEvent(
    gamepadId: rawEvent.gamepadId,
    timestamp: rawEvent.timestamp,
    axis: axis,
    value: rawEvent.value,
    rawEvent: rawEvent,
  );
}
