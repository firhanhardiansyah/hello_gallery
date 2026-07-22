import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

enum DesktopWindowPlatform { macOS, windows, other }

DesktopWindowPlatform get currentDesktopWindowPlatform => Platform.isMacOS
    ? DesktopWindowPlatform.macOS
    : Platform.isWindows
    ? DesktopWindowPlatform.windows
    : DesktopWindowPlatform.other;

class DesktopWindowTitleBar extends StatelessWidget {
  const DesktopWindowTitleBar({
    required this.child,
    required this.backgroundColor,
    this.reserveMacOSWindowButtons = false,
    this.showWindowsCaptionControls = true,
    this.platform,
    this.windowsCaptionControls,
    super.key,
  });

  static const double height = 56;
  static const double macOSHeight = height;
  static const double macOSWindowButtonsInset = 80;

  final Widget child;
  final Color backgroundColor;
  final bool reserveMacOSWindowButtons;
  final bool showWindowsCaptionControls;
  final DesktopWindowPlatform? platform;
  final Widget? windowsCaptionControls;

  DesktopWindowPlatform get _platform =>
      platform ?? currentDesktopWindowPlatform;

  @override
  Widget build(BuildContext context) {
    final currentPlatform = _platform;
    final showCaptionControls =
        currentPlatform == DesktopWindowPlatform.windows &&
        showWindowsCaptionControls;
    final resolvedHeight = currentPlatform == DesktopWindowPlatform.macOS
        ? macOSHeight
        : height;
    return Material(
      color: backgroundColor,
      child: SizedBox(
        height: resolvedHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DesktopDragToMoveArea(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    left:
                        currentPlatform == DesktopWindowPlatform.macOS &&
                            reserveMacOSWindowButtons
                        ? macOSWindowButtonsInset
                        : 0,
                  ),
                  child: child,
                ),
              ),
            ),
            if (showCaptionControls)
              windowsCaptionControls ?? const DesktopWindowsCaptionControls(),
          ],
        ),
      ),
    );
  }
}

class DesktopDragToMoveArea extends StatefulWidget {
  const DesktopDragToMoveArea({
    required this.child,
    this.onDoubleTap,
    super.key,
  });

  final Widget child;
  final VoidCallback? onDoubleTap;

  @override
  State<DesktopDragToMoveArea> createState() => _DesktopDragToMoveAreaState();
}

class _DesktopDragToMoveAreaState extends State<DesktopDragToMoveArea> {
  static const _doubleClickInterval = Duration(milliseconds: 500);
  static const _doubleClickDistance = 6.0;

  Duration? _lastPrimaryDownTime;
  Offset? _lastPrimaryDownPosition;

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse ||
        event.buttons & kPrimaryMouseButton == 0) {
      _resetDoubleClick();
      return;
    }
    final lastTime = _lastPrimaryDownTime;
    final lastPosition = _lastPrimaryDownPosition;
    final isDoubleClick =
        lastTime != null &&
        lastPosition != null &&
        event.timeStamp - lastTime <= _doubleClickInterval &&
        (event.localPosition - lastPosition).distance <= _doubleClickDistance;
    if (!isDoubleClick) {
      _lastPrimaryDownTime = event.timeStamp;
      _lastPrimaryDownPosition = event.localPosition;
      return;
    }

    _resetDoubleClick();
    final onDoubleTap = widget.onDoubleTap;
    if (onDoubleTap != null) {
      onDoubleTap();
    } else {
      unawaited(_toggleMaximized());
    }
  }

  void _resetDoubleClick() {
    _lastPrimaryDownTime = null;
    _lastPrimaryDownPosition = null;
  }

  Future<void> _toggleMaximized() async {
    if (await windowManager.isFullScreen()) return;
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _handlePointerDown,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        windowManager.startDragging();
      },
      child: widget.child,
    ),
  );
}

class DesktopWindowsCaptionControls extends StatefulWidget {
  const DesktopWindowsCaptionControls({super.key});

  @override
  State<DesktopWindowsCaptionControls> createState() =>
      _DesktopWindowsCaptionControlsState();
}

class _DesktopWindowsCaptionControlsState
    extends State<DesktopWindowsCaptionControls>
    with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _readMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _readMaximizedState() async {
    final maximized = await windowManager.isMaximized();
    if (mounted) setState(() => _maximized = maximized);
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      key: const ValueKey('windows-caption-controls'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WindowCaptionButton.minimize(
          brightness: brightness,
          onPressed: windowManager.minimize,
        ),
        if (_maximized)
          WindowCaptionButton.unmaximize(
            brightness: brightness,
            onPressed: windowManager.unmaximize,
          )
        else
          WindowCaptionButton.maximize(
            brightness: brightness,
            onPressed: windowManager.maximize,
          ),
        WindowCaptionButton.close(
          brightness: brightness,
          onPressed: windowManager.close,
        ),
      ],
    );
  }
}
