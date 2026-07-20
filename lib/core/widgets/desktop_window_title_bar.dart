import 'dart:io';

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

  static const double height = 60;
  static const double macOSWindowButtonsInset = 72;

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
    return Material(
      color: backgroundColor,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DragToMoveArea(child: SizedBox.expand()),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
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
                if (showCaptionControls)
                  windowsCaptionControls ??
                      const DesktopWindowsCaptionControls(),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
