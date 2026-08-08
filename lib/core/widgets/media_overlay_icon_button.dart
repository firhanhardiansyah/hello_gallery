import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_color_tokens.dart';

class MediaOverlayIconButton extends StatelessWidget {
  const MediaOverlayIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 40,
    super.key,
  });

  final String tooltip;
  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final enabled = onPressed != null;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        backgroundColor: appColors.mediaControlSurface.withValues(alpha: 0.3),
        disabledBackgroundColor: appColors.mediaControlSurface.withValues(
          alpha: 0.18,
        ),
        hoverColor: appColors.mediaControlSurface.withValues(alpha: 0.2),
        highlightColor: appColors.mediaControlSurface.withValues(alpha: 0.3),
      ),
      icon: HugeIcon(
        icon: icon,
        color: enabled ? color ?? appColors.onMedia : appColors.onMediaMuted,
      ),
    );
  }
}
