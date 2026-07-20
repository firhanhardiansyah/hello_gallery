import 'package:flutter/material.dart';

class MediaPreviewInteractionSurface extends StatelessWidget {
  const MediaPreviewInteractionSurface({
    required this.child,
    required this.onDoubleTap,
    this.onTap,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    child: child,
  );
}
