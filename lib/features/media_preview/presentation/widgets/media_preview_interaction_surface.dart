import 'package:flutter/material.dart';

class MediaPreviewInteractionSurface extends StatelessWidget {
  const MediaPreviewInteractionSurface({
    required this.child,
    required this.onDoubleTap,
    this.onTap,
    this.onSecondaryTapDown,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback onDoubleTap;
  final GestureTapDownCallback? onSecondaryTapDown;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onSecondaryTapDown: onSecondaryTapDown,
    child: child,
  );
}
