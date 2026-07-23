import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gamepads/gamepads.dart';

import 'media_preview_scroll_input.dart';

final class MediaPreviewInputHandler {
  MediaPreviewInputHandler({
    required this.onPrevious,
    required this.onNext,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.onTogglePlay,
    required this.onToggleMute,
    required this.onRotate,
    required this.onToggleRotationLock,
    required this.onToggleLoop,
    required this.onToggleSidebar,
    required this.onToggleFullscreen,
    required this.onClose,
    required this.onEscape,
    required this.onRequestFocus,
    bool Function()? isPrimaryModifierPressed,
  }) : _isPrimaryModifierPressed =
           isPrimaryModifierPressed ?? _defaultPrimaryModifierPressed;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;
  final VoidCallback onRotate;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onToggleLoop;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onClose;
  final VoidCallback onEscape;
  final VoidCallback onRequestFocus;
  final bool Function() _isPrimaryModifierPressed;

  final _scrollInput = MediaPreviewScrollInput();
  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;
  bool _started = false;
  bool _disposed = false;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    _gamepadSubscription = Gamepads.normalizedEvents.listen(handleGamepadEvent);
  }

  void dispose() {
    _disposed = true;
    if (_started) {
      HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    }
    unawaited(_gamepadSubscription?.cancel());
    _scrollInput.dispose();
  }

  void handlePointerSignal(PointerSignalEvent event) {
    if (_disposed) return;
    if (event is! PointerScrollEvent) return;
    switch (_scrollInput.handle(event.scrollDelta)) {
      case < 0:
        onPrevious();
      case > 0:
        onNext();
    }
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (_disposed) return false;
    return handleKeyEvent(event) == KeyEventResult.handled;
  }

  void handleGamepadEvent(NormalizedGamepadEvent event) {
    if (_disposed) return;
    final button = event.button;
    if (button == null || event.value < 0.5) return;
    switch (button) {
      case GamepadButton.dpadUp:
        onPrevious();
      case GamepadButton.dpadDown:
        onNext();
      case GamepadButton.dpadLeft:
        onSeekBackward();
      case GamepadButton.dpadRight:
        onSeekForward();
      case GamepadButton.a:
        onTogglePlay();
      case GamepadButton.x:
        onToggleMute();
      case GamepadButton.y:
      case GamepadButton.start:
        onToggleFullscreen();
      case GamepadButton.touchpad:
        onToggleSidebar();
      case GamepadButton.back:
      case GamepadButton.b:
        onClose();
      case GamepadButton.home:
      case GamepadButton.leftBumper:
      case GamepadButton.rightBumper:
      case GamepadButton.leftTrigger:
      case GamepadButton.rightTrigger:
      case GamepadButton.leftStick:
      case GamepadButton.rightStick:
        return;
    }
  }

  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        onRequestFocus();
        onPrevious();
      case LogicalKeyboardKey.arrowDown:
        onRequestFocus();
        onNext();
      case LogicalKeyboardKey.arrowLeft:
        onSeekBackward();
      case LogicalKeyboardKey.arrowRight:
        onSeekForward();
      case LogicalKeyboardKey.space:
        onTogglePlay();
      case LogicalKeyboardKey.keyM:
        onToggleMute();
      case LogicalKeyboardKey.keyR:
        if (_isPrimaryModifierPressed()) {
          onToggleRotationLock();
        } else {
          onRotate();
        }
      case LogicalKeyboardKey.keyL:
        onToggleLoop();
      case LogicalKeyboardKey.keyS:
        onToggleSidebar();
      case LogicalKeyboardKey.keyF:
        onToggleFullscreen();
      case LogicalKeyboardKey.escape:
        onEscape();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}

bool _defaultPrimaryModifierPressed() {
  final keyboard = HardwareKeyboard.instance;
  return keyboard.isControlPressed || keyboard.isMetaPressed;
}
