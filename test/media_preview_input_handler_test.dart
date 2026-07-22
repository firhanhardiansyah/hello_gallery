import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:hello_gallery/features/media_preview/presentation/input/media_preview_input_handler.dart';

void main() {
  test('maps keyboard shortcuts to preview actions', () {
    var nextCount = 0;
    var seekBackwardCount = 0;
    var muteCount = 0;
    var rotateCount = 0;
    var loopCount = 0;
    var fullscreenCount = 0;
    var closeCount = 0;
    var sidebarCount = 0;
    var escapeCount = 0;
    var focusCount = 0;
    final handler = MediaPreviewInputHandler(
      onPrevious: _noop,
      onNext: () => nextCount++,
      onSeekBackward: () => seekBackwardCount++,
      onSeekForward: _noop,
      onTogglePlay: _noop,
      onToggleMute: () => muteCount++,
      onRotate: () => rotateCount++,
      onToggleLoop: () => loopCount++,
      onToggleSidebar: () => sidebarCount++,
      onToggleFullscreen: () => fullscreenCount++,
      onClose: () => closeCount++,
      onEscape: () => escapeCount++,
      onRequestFocus: () => focusCount++,
    );
    addTearDown(handler.dispose);

    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown)),
      KeyEventResult.handled,
    );
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowLeft));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyM));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyR));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyL));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyF));
    handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.escape));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.back));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.b));
    handler.handleGamepadEvent(_gamepadButton(GamepadButton.touchpad));

    expect(nextCount, 1);
    expect(seekBackwardCount, 1);
    expect(muteCount, 1);
    expect(rotateCount, 1);
    expect(loopCount, 1);
    expect(fullscreenCount, 1);
    expect(closeCount, 2);
    expect(sidebarCount, 1);
    expect(escapeCount, 1);
    expect(focusCount, 1);
  });
}

NormalizedGamepadEvent _gamepadButton(GamepadButton button) {
  final rawEvent = GamepadEvent(
    gamepadId: 'test-controller',
    timestamp: 0,
    type: KeyType.button,
    key: button.name,
    value: 1,
  );
  return NormalizedGamepadEvent(
    gamepadId: rawEvent.gamepadId,
    timestamp: rawEvent.timestamp,
    button: button,
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
