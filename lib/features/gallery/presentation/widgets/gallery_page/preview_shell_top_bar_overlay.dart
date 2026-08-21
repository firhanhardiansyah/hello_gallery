import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

class PreviewShellTopBarOverlay extends StatefulWidget {
  const PreviewShellTopBarOverlay({
    required this.visible,
    required this.child,
    this.forceHidden = false,
    super.key,
  });

  final bool visible;
  final Widget child;
  final bool forceHidden;

  @override
  State<PreviewShellTopBarOverlay> createState() =>
      _PreviewShellTopBarOverlayState();
}

class _PreviewShellTopBarOverlayState extends State<PreviewShellTopBarOverlay> {
  bool _isHovered = false;

  @override
  void didUpdateWidget(covariant PreviewShellTopBarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.forceHidden && widget.forceHidden) _isHovered = false;
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = !widget.forceHidden && (widget.visible || _isHovered);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        offset: isVisible ? Offset.zero : const Offset(0, -1),
        child: AnimatedOpacity(
          key: const ValueKey('preview-shell-top-bar-opacity'),
          duration: const Duration(milliseconds: 150),
          opacity: isVisible ? 1 : 0,
          child: IgnorePointer(
            key: const ValueKey('preview-shell-top-bar-pointer'),
            ignoring: !isVisible,
            child: MouseRegion(
              key: const ValueKey('preview-shell-top-bar-mouse-region'),
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: DecoratedBox(
                key: const ValueKey('preview-shell-top-bar-gradient'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.appColors.mediaOverlay.withValues(alpha: 0.58),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
