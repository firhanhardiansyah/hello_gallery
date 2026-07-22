import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gamepads/gamepads.dart';

class GalleryInputHandler {
  GalleryInputHandler({
    required this.isEnabled,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onActivate,
    required this.onBack,
    required this.onGamepadBack,
    required this.onToggleSelectAll,
    required this.onToggleSidebar,
    required this.onToggleFullscreen,
  });

  final bool Function() isEnabled;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onActivate;
  final VoidCallback onBack;
  final VoidCallback onGamepadBack;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleFullscreen;

  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;

  void start() {
    HardwareKeyboard.instance.addHandler(_handleKey);
    _gamepadSubscription = Gamepads.normalizedEvents.listen(handleGamepadEvent);
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    unawaited(_gamepadSubscription?.cancel());
  }

  bool _handleKey(KeyEvent event) {
    return handleKeyEvent(event) == KeyEventResult.handled;
  }

  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (!isEnabled() || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      final keyboard = HardwareKeyboard.instance;
      if (!keyboard.isControlPressed && !keyboard.isMetaPressed) {
        return KeyEventResult.ignored;
      }
      onToggleSelectAll();
      return KeyEventResult.handled;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        onMoveUp();
      case LogicalKeyboardKey.arrowDown:
        onMoveDown();
      case LogicalKeyboardKey.arrowLeft:
        onMoveLeft();
      case LogicalKeyboardKey.arrowRight:
        onMoveRight();
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        onActivate();
      case LogicalKeyboardKey.keyS:
        onToggleSidebar();
      case LogicalKeyboardKey.keyF:
        onToggleFullscreen();
      case LogicalKeyboardKey.escape:
        onBack();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void handleGamepadEvent(NormalizedGamepadEvent event) {
    if (!isEnabled() || event.button == null || event.value < 0.5) return;
    switch (event.button!) {
      case GamepadButton.dpadUp:
        onMoveUp();
      case GamepadButton.dpadDown:
        onMoveDown();
      case GamepadButton.dpadLeft:
        onMoveLeft();
      case GamepadButton.dpadRight:
        onMoveRight();
      case GamepadButton.a:
        onActivate();
      case GamepadButton.b:
        onGamepadBack();
      case GamepadButton.back:
      case GamepadButton.touchpad:
        onToggleSidebar();
      case GamepadButton.y:
      case GamepadButton.start:
        onToggleFullscreen();
      case GamepadButton.home:
      case GamepadButton.x:
      case GamepadButton.leftBumper:
      case GamepadButton.rightBumper:
      case GamepadButton.leftTrigger:
      case GamepadButton.rightTrigger:
      case GamepadButton.leftStick:
      case GamepadButton.rightStick:
        return;
    }
  }
}
