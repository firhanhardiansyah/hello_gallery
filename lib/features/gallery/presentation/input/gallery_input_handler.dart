import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gamepads/gamepads.dart';

class GalleryInputHandler {
  static const _navigationDebounce = Duration(milliseconds: 80);

  GalleryInputHandler({
    required this.isEnabled,
    required this.isNavigationEnabled,
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
    required this.onNavigateBack,
    required this.onNavigateForward,
  });

  final bool Function() isEnabled;
  final bool Function() isNavigationEnabled;
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
  final VoidCallback onNavigateBack;
  final VoidCallback onNavigateForward;

  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;
  Duration? _lastNavigationTime;
  int? _lastNavigationButton;

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
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.browserBack) {
      return _handleNavigationShortcut(
        button: kBackMouseButton,
        timeStamp: event.timeStamp,
        callback: onNavigateBack,
      );
    }
    if (event.logicalKey == LogicalKeyboardKey.browserForward) {
      return _handleNavigationShortcut(
        button: kForwardMouseButton,
        timeStamp: event.timeStamp,
        callback: onNavigateForward,
      );
    }
    if (!isEnabled()) return KeyEventResult.ignored;
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

  void handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    if (event.buttons & kBackMouseButton != 0) {
      _handleNavigationShortcut(
        button: kBackMouseButton,
        timeStamp: event.timeStamp,
        callback: onNavigateBack,
      );
    } else if (event.buttons & kForwardMouseButton != 0) {
      _handleNavigationShortcut(
        button: kForwardMouseButton,
        timeStamp: event.timeStamp,
        callback: onNavigateForward,
      );
    }
  }

  KeyEventResult _handleNavigationShortcut({
    required int button,
    required Duration timeStamp,
    required VoidCallback callback,
  }) {
    if (!isNavigationEnabled()) return KeyEventResult.ignored;
    final lastTime = _lastNavigationTime;
    final elapsed = lastTime == null ? null : timeStamp - lastTime;
    if (_lastNavigationButton == button &&
        elapsed != null &&
        !elapsed.isNegative &&
        elapsed < _navigationDebounce) {
      return KeyEventResult.handled;
    }
    _lastNavigationButton = button;
    _lastNavigationTime = timeStamp;
    callback();
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
