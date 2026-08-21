import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gamepads/gamepads.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';

class VirtualCursorOverlay extends StatefulWidget {
  const VirtualCursorOverlay({
    required this.child,
    this.gamepadEvents,
    this.idleTimeout = const Duration(seconds: 3),
    this.showCursor = true,
    super.key,
  });

  final Widget child;
  final Stream<NormalizedGamepadEvent>? gamepadEvents;
  final Duration idleTimeout;
  final bool showCursor;

  @override
  State<VirtualCursorOverlay> createState() => _VirtualCursorOverlayState();
}

class _VirtualCursorOverlayState extends State<VirtualCursorOverlay>
    with SingleTickerProviderStateMixin {
  static const _deviceId = 94721;
  static const _deadZone = 0.18;
  static const _maxSpeed = 900.0;
  static const _maxScrollSpeed = 700.0;

  late final Ticker _ticker;
  StreamSubscription<NormalizedGamepadEvent>? _subscription;
  Duration? _lastTick;
  Offset _position = Offset.zero;
  Offset _lastGlobalPosition = Offset.zero;
  Size _viewportSize = Size.zero;
  double _rightX = 0;
  double _rightY = 0;
  double _leftX = 0;
  double _leftY = 0;
  bool _precisionMode = false;
  bool _primaryPressed = false;
  bool _pointerAdded = false;
  bool _visible = false;
  bool _usingGamepadPointer = false;
  Duration _lastActivity = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _subscription = (widget.gamepadEvents ?? Gamepads.normalizedEvents).listen(
      _onGamepadEvent,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    unawaited(_subscription?.cancel());
    _removeVirtualPointer();
    super.dispose();
  }

  void _onGamepadEvent(NormalizedGamepadEvent event) {
    final axis = event.axis;
    if (axis == GamepadAxis.leftStickX) {
      _leftX = event.value;
      return;
    }
    if (axis == GamepadAxis.leftStickY) {
      _leftY = event.value;
      return;
    }
    if (axis == GamepadAxis.rightStickX) {
      _rightX = event.value;
      return;
    }
    if (axis == GamepadAxis.rightStickY) {
      _rightY = event.value;
      return;
    }

    final button = event.button;
    if (button == GamepadButton.leftBumper) {
      _precisionMode = event.value >= 0.5;
    } else if (button == GamepadButton.rightBumper) {
      _setPrimaryPressed(event.value >= 0.5);
    } else if (button == GamepadButton.rightStick && event.value >= 0.5) {
      _centerCursor();
    }
  }

  void _onTick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null || _viewportSize.isEmpty) return;
    final seconds = (elapsed - previous).inMicroseconds / 1000000;
    final x = _applyCurve(_rightX);
    final y = _applyCurve(_rightY);
    final scrollX = _applyCurve(_leftX);
    final scrollY = _applyCurve(_leftY);
    if (x == 0 && y == 0 && scrollX == 0 && scrollY == 0) {
      if (_visible &&
          !_primaryPressed &&
          elapsed - _lastActivity > widget.idleTimeout) {
        _removeVirtualPointer();
        setState(() => _visible = false);
      }
      return;
    }

    _activateGamepadPointer();
    final speed = _maxSpeed * (_precisionMode ? 0.25 : 1.0);
    final delta = Offset(x * speed * seconds, -y * speed * seconds);
    final next = Offset(
      (_position.dx + delta.dx).clamp(0.0, _viewportSize.width),
      (_position.dy + delta.dy).clamp(0.0, _viewportSize.height),
    );
    final actualDelta = next - _position;
    _position = next;
    _lastActivity = elapsed;
    if (!_visible) setState(() => _visible = true);
    if (actualDelta != Offset.zero) _dispatchMove(actualDelta);
    if (scrollX != 0 || scrollY != 0) {
      _dispatchScroll(
        Offset(
          scrollX * _maxScrollSpeed * seconds,
          -scrollY * _maxScrollSpeed * seconds,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  double _applyCurve(double value) {
    final magnitude = value.abs();
    if (magnitude <= _deadZone) return 0;
    final normalized = (magnitude - _deadZone) / (1 - _deadZone);
    return math.pow(normalized, 2).toDouble() * value.sign;
  }

  void _centerCursor() {
    if (_viewportSize.isEmpty) return;
    _activateGamepadPointer();
    _position = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    _lastActivity = _lastTick ?? Duration.zero;
    setState(() => _visible = true);
    _dispatchMove(Offset.zero);
  }

  void _setPrimaryPressed(bool pressed) {
    if (_primaryPressed == pressed || _viewportSize.isEmpty) return;
    _activateGamepadPointer();
    _ensurePointerAdded();
    _primaryPressed = pressed;
    _lastActivity = _lastTick ?? Duration.zero;
    if (!_visible) setState(() => _visible = true);
    final globalPosition = _globalPosition;
    GestureBinding.instance.handlePointerEvent(
      pressed
          ? PointerDownEvent(
              pointer: _deviceId,
              device: _deviceId,
              position: globalPosition,
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            )
          : PointerUpEvent(
              pointer: _deviceId,
              device: _deviceId,
              position: globalPosition,
              kind: PointerDeviceKind.mouse,
            ),
    );
  }

  void _dispatchMove(Offset delta) {
    _ensurePointerAdded();
    final event = _primaryPressed
        ? PointerMoveEvent(
            pointer: _deviceId,
            device: _deviceId,
            position: _globalPosition,
            delta: delta,
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          )
        : PointerHoverEvent(
            pointer: _deviceId,
            device: _deviceId,
            position: _globalPosition,
            delta: delta,
            kind: PointerDeviceKind.mouse,
          );
    GestureBinding.instance.handlePointerEvent(event);
  }

  void _dispatchScroll(Offset delta) {
    _ensurePointerAdded();
    GestureBinding.instance.handlePointerEvent(
      PointerScrollEvent(
        device: _deviceId,
        position: _globalPosition,
        scrollDelta: delta,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  void _ensurePointerAdded() {
    if (_pointerAdded) return;
    _pointerAdded = true;
    GestureBinding.instance.handlePointerEvent(
      PointerAddedEvent(
        pointer: _deviceId,
        device: _deviceId,
        position: _globalPosition,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  void _removeVirtualPointer() {
    if (!_pointerAdded) return;
    _pointerAdded = false;
    GestureBinding.instance.handlePointerEvent(
      PointerRemovedEvent(
        pointer: _deviceId,
        device: _deviceId,
        position: _globalPosition,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  void _activateGamepadPointer() {
    if (_usingGamepadPointer) return;
    if (mounted) setState(() => _usingGamepadPointer = true);
  }

  void _activateNativePointer() {
    if (!_usingGamepadPointer && !_visible) return;
    setState(() {
      _usingGamepadPointer = false;
      _visible = false;
    });
  }

  Offset get _globalPosition {
    if (!context.mounted) return _lastGlobalPosition;
    final renderObject = context.findRenderObject();
    _lastGlobalPosition = renderObject is RenderBox
        ? renderObject.localToGlobal(_position)
        : _position;
    return _lastGlobalPosition;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _viewportSize && size.isFinite) {
          _viewportSize = size;
          if (_position == Offset.zero) {
            _position = Offset(size.width / 2, size.height / 2);
          } else {
            _position = Offset(
              _position.dx.clamp(0.0, size.width),
              _position.dy.clamp(0.0, size.height),
            );
          }
        }
        return MouseRegion(
          cursor: _usingGamepadPointer
              ? SystemMouseCursors.none
              : MouseCursor.defer,
          onHover: (event) {
            if (event.device != _deviceId && mounted) {
              _activateNativePointer();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (widget.showCursor && _visible)
                Positioned(
                  left: _position.dx - 9,
                  top: _position.dy - 9,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey('virtual-cursor-indicator'),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.appColors.onMedia,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.appColors.shadow,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const SizedBox.square(dimension: 18),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
