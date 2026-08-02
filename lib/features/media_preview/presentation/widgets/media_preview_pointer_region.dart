import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/media_preview_timing.dart';

class MediaPreviewPointerRegion extends StatefulWidget {
  const MediaPreviewPointerRegion({
    required this.onActivity,
    required this.onExitIdle,
    required this.child,
    this.cursor = MouseCursor.defer,
    this.exitDelay = MediaPreviewTiming.previewExitHide,
    super.key,
  });

  final VoidCallback onActivity;
  final VoidCallback onExitIdle;
  final Widget child;
  final MouseCursor cursor;
  final Duration exitDelay;

  @override
  State<MediaPreviewPointerRegion> createState() =>
      _MediaPreviewPointerRegionState();
}

class _MediaPreviewPointerRegionState extends State<MediaPreviewPointerRegion> {
  Timer? _exitTimer;

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.cursor,
    onEnter: (_) => _handleActivity(),
    onHover: (_) => _handleActivity(),
    onExit: (_) => _scheduleExit(),
    child: widget.child,
  );

  void _handleActivity() {
    _exitTimer?.cancel();
    widget.onActivity();
  }

  void _scheduleExit() {
    _exitTimer?.cancel();
    _exitTimer = Timer(widget.exitDelay, widget.onExitIdle);
  }
}
