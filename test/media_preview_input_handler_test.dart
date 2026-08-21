import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:hello_gallery/features/media_preview/presentation/input/media_preview_input_handler.dart';

void main() {
  test('maps keyboard and gamepad shortcuts to preview actions', () {
    var nextCount = 0;
    var seekBackwardCount = 0;
    var muteCount = 0;
    var rotateCount = 0;
    var rotationLockCount = 0;
    var loopCount = 0;
    var filmstripCount = 0;
    var fullscreenCount = 0;
    var closeCount = 0;
    var sidebarCount = 0;
    var topBarCount = 0;
    var cleanPreviewCount = 0;
    var escapeCount = 0;
    var focusCount = 0;
    var gamepadInteractionCount = 0;
    var primaryModifierPressed = false;
    final handler = MediaPreviewInputHandler(
      onPrevious: _noop,
      onNext: () => nextCount++,
      onSeekBackward: () => seekBackwardCount++,
      onSeekForward: _noop,
      onTogglePlay: _noop,
      onToggleMute: () => muteCount++,
      onRotate: () => rotateCount++,
      onToggleRotationLock: () => rotationLockCount++,
      onToggleLoop: () => loopCount++,
      onToggleFilmstrip: () => filmstripCount++,
      onToggleSidebar: () => sidebarCount++,
      onToggleTopBar: () => topBarCount++,
      onToggleCleanPreview: () => cleanPreviewCount++,
      onToggleFullscreen: () => fullscreenCount++,
      onClose: () => closeCount++,
      onEscape: () => escapeCount++,
      onRequestFocus: () => focusCount++,
      onGamepadInteraction: () => gamepadInteractionCount++,
      isPrimaryModifierPressed: () => primaryModifierPressed,
    );
    addTearDown(handler.dispose);

    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown)),
      KeyEventResult.handled,
    );
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowLeft));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyM));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyR));
    primaryModifierPressed = true;
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyR));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyL));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyG));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyT));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyH));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyF));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.escape));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.back));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.b));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.touchpad));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.dpadLeft));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.a));
    handler.handleGamepadEvent(_gamepadAxis(GamepadAxis.rightTrigger));
    handler.handleGamepadEvent(_gamepadAxis(GamepadAxis.rightTrigger));
    handler.handleGamepadEvent(
      _gamepadAxis(GamepadAxis.rightTrigger, value: 0),
    );
    handler.handleGamepadEvent(_gamepadAxis(GamepadAxis.rightTrigger));
    handler.handleGamepadEvent(_gamepadAxis(GamepadAxis.leftTrigger));
    handler.handleGamepadEvent(_gamepadAxis(GamepadAxis.leftTrigger));
    handler.handleGamepadEvent(_gamepadAxis(GamepadAxis.leftTrigger, value: 0));
    handler.handleGamepadEvent(_gamepadAxis(GamepadAxis.leftTrigger));

    expect(nextCount, 1);
    expect(seekBackwardCount, 2);
    expect(muteCount, 1);
    expect(rotateCount, 3);
    expect(rotationLockCount, 3);
    expect(loopCount, 1);
    expect(filmstripCount, 1);
    expect(fullscreenCount, 1);
    expect(closeCount, 1);
    expect(sidebarCount, 2);
    expect(topBarCount, 1);
    expect(cleanPreviewCount, 1);
    expect(escapeCount, 1);
    expect(focusCount, 1);
    expect(gamepadInteractionCount, 6);
  });

  testWidgets('uses unclaimed pointer scroll for media navigation', (
    tester,
  ) async {
    var nextCount = 0;
    final handler = MediaPreviewInputHandler(
      onPrevious: _noop,
      onNext: () => nextCount++,
      onSeekBackward: _noop,
      onSeekForward: _noop,
      onTogglePlay: _noop,
      onToggleMute: _noop,
      onRotate: _noop,
      onToggleRotationLock: _noop,
      onToggleLoop: _noop,
      onToggleFilmstrip: _noop,
      onToggleSidebar: _noop,
      onToggleTopBar: _noop,
      onToggleCleanPreview: _noop,
      onToggleFullscreen: _noop,
      onClose: _noop,
      onEscape: _noop,
      onRequestFocus: _noop,
      onGamepadInteraction: _noop,
    );
    addTearDown(handler.dispose);

    await tester.pumpWidget(
      Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: handler.handlePointerSignal,
        child: const SizedBox.expand(),
      ),
    );
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(10, 10),
        scrollDelta: Offset(0, 30),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(nextCount, 1);
  });

  testWidgets('reserves primary-modifier scroll for canvas zoom', (
    tester,
  ) async {
    var nextCount = 0;
    var primaryModifierPressed = true;
    final handler = MediaPreviewInputHandler(
      onPrevious: _noop,
      onNext: () => nextCount++,
      onSeekBackward: _noop,
      onSeekForward: _noop,
      onTogglePlay: _noop,
      onToggleMute: _noop,
      onRotate: _noop,
      onToggleRotationLock: _noop,
      onToggleLoop: _noop,
      onToggleFilmstrip: _noop,
      onToggleSidebar: _noop,
      onToggleTopBar: _noop,
      onToggleCleanPreview: _noop,
      onToggleFullscreen: _noop,
      onClose: _noop,
      onEscape: _noop,
      onRequestFocus: _noop,
      onGamepadInteraction: _noop,
      isPrimaryModifierPressed: () => primaryModifierPressed,
    );
    addTearDown(handler.dispose);

    await tester.pumpWidget(
      Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: handler.handlePointerSignal,
        child: const SizedBox.expand(),
      ),
    );
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(10, 10),
        scrollDelta: Offset(0, 30),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(nextCount, 0);

    primaryModifierPressed = false;
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(10, 10),
        scrollDelta: Offset(0, 30),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(nextCount, 1);
  });
}

NormalizedGamepadEvent _gamepadButton(
  GamepadButton button, {
  double value = 1,
}) {
  final rawEvent = GamepadEvent(
    gamepadId: 'test-controller',
    timestamp: 0,
    type: KeyType.button,
    key: button.name,
    value: value,
  );
  return NormalizedGamepadEvent(
    gamepadId: rawEvent.gamepadId,
    timestamp: rawEvent.timestamp,
    button: button,
    value: rawEvent.value,
    rawEvent: rawEvent,
  );
}

NormalizedGamepadEvent _gamepadAxis(GamepadAxis axis, {double value = 1}) {
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

KeyDownEvent _keyDown(LogicalKeyboardKey key) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.arrowDown,
  logicalKey: key,
  timeStamp: Duration.zero,
);

void _noop() {}
