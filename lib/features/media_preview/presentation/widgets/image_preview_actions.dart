import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

class ImagePreviewActions extends StatelessWidget {
  const ImagePreviewActions({
    required this.visible,
    required this.onRotate,
    required this.onInteraction,
    super.key,
  });

  final bool visible;
  final VoidCallback onRotate;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context) => Positioned(
    right: AppSpacing.lg,
    bottom: AppSpacing.lg,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: IconButton(
          tooltip: 'Rotate clockwise',
          onPressed: () {
            onInteraction();
            onRotate();
          },
          style: IconButton.styleFrom(
            fixedSize: const Size.square(44),
            backgroundColor: context.appColors.mediaControlSurface.withValues(
              alpha: 0.3,
            ),
            foregroundColor: context.appColors.onMedia,
            hoverColor: context.appColors.mediaControlSurface.withValues(
              alpha: 0.2,
            ),
          ),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedRotateClockwise),
        ),
      ),
    ),
  );
}
