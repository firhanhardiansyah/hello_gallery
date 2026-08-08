import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/core/widgets/media_overlay_icon_button.dart';
import 'package:hugeicons/hugeicons.dart';

class GalleryNavigationControls extends StatelessWidget {
  const GalleryNavigationControls({
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.backTooltip,
    required this.onBack,
    required this.onForward,
    this.overlayStyle = false,
    super.key,
  });

  final bool sidebarVisible;
  final VoidCallback onToggleSidebar;
  final String backTooltip;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final bool overlayStyle;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _buildButton(
        tooltip: sidebarVisible ? 'Hide sidebar' : 'Show sidebar',
        onPressed: onToggleSidebar,
        icon: sidebarVisible
            ? HugeIcons.strokeRoundedSidebarLeft
            : HugeIcons.strokeRoundedPanelLeftOpen,
      ),
      _buildButton(
        tooltip: backTooltip,
        onPressed: onBack,
        icon: HugeIcons.strokeRoundedArrowLeft02,
      ),
      _buildButton(
        tooltip: 'Forward',
        onPressed: onForward,
        icon: HugeIcons.strokeRoundedArrowRight02,
      ),
    ];
    return Row(
      key: const ValueKey('gallery-navigation-controls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < buttons.length; index++) ...[
          if (overlayStyle && index > 0) const SizedBox(width: AppSpacing.xs),
          buttons[index],
        ],
      ],
    );
  }

  Widget _buildButton({
    required String tooltip,
    required VoidCallback? onPressed,
    required List<List<dynamic>> icon,
  }) {
    if (overlayStyle) {
      return MediaOverlayIconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
      );
    }
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: HugeIcon(icon: icon),
    );
  }
}
