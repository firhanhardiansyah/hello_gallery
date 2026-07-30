import 'package:flutter/material.dart';

class PreviewShellTopBarOverlay extends StatelessWidget {
  const PreviewShellTopBarOverlay({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        offset: visible ? Offset.zero : const Offset(0, -1),
        child: AnimatedOpacity(
          key: const ValueKey('preview-shell-top-bar-opacity'),
          duration: const Duration(milliseconds: 150),
          opacity: visible ? 1 : 0,
          child: IgnorePointer(
            key: const ValueKey('preview-shell-top-bar-pointer'),
            ignoring: !visible,
            child: child,
          ),
        ),
      ),
    );
  }
}
