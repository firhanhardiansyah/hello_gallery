import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

class ImagePreviewActions extends StatelessWidget {
  const ImagePreviewActions({
    required this.visible,
    required this.isRotationLocked,
    required this.filmstripVisible,
    required this.bottomInset,
    required this.onRotate,
    required this.onToggleRotationLock,
    required this.onToggleFilmstrip,
    required this.onInteraction,
    super.key,
  });

  final bool visible;
  final bool isRotationLocked;
  final bool filmstripVisible;
  final double bottomInset;
  final VoidCallback onRotate;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onToggleFilmstrip;
  final VoidCallback onInteraction;

  static const _controlSize = 44.0;

  @override
  Widget build(BuildContext context) => Positioned(
    right: AppSpacing.lg,
    bottom: bottomInset,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          height: _controlSize,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appColors.mediaControlSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(_controlSize / 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _button(
                context: context,
                tooltip: 'Rotate clockwise',
                icon: HugeIcons.strokeRoundedRotateClockwise,
                onPressed: onRotate,
              ),
              _divider(context),
              _button(
                context: context,
                tooltip: isRotationLocked ? 'Unlock rotation' : 'Lock rotation',
                icon: isRotationLocked
                    ? HugeIcons.strokeRoundedScreenLockRotation
                    : HugeIcons.strokeRoundedSquareUnlock01,
                color: isRotationLocked
                    ? Theme.of(context).colorScheme.primary
                    : null,
                onPressed: onToggleRotationLock,
              ),
              _divider(context),
              _button(
                context: context,
                tooltip: filmstripVisible
                    ? 'Hide media list (G)'
                    : 'Show media list (G)',
                icon: HugeIcons.strokeRoundedGalleryHorizontalEnd,
                color: filmstripVisible
                    ? Theme.of(context).colorScheme.primary
                    : null,
                onPressed: onToggleFilmstrip,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _divider(BuildContext context) => Container(
    width: 1,
    height: _controlSize / 2,
    color: context.appColors.onMediaMuted.withValues(alpha: 0.35),
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
  );

  Widget _button({
    required BuildContext context,
    required String tooltip,
    required List<List<dynamic>> icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        onInteraction();
        onPressed();
      },
      style: IconButton.styleFrom(
        fixedSize: const Size.square(_controlSize),
        backgroundColor: Colors.transparent,
        foregroundColor: context.appColors.onMedia,
        hoverColor: context.appColors.mediaControlSurface.withValues(
          alpha: 0.2,
        ),
        highlightColor: context.appColors.mediaControlSurface.withValues(
          alpha: 0.3,
        ),
      ),
      icon: HugeIcon(icon: icon, color: color ?? context.appColors.onMedia),
    );
  }
}
