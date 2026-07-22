import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class GalleryNavigationControls extends StatelessWidget {
  const GalleryNavigationControls({
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.backTooltip,
    required this.onBack,
    required this.onForward,
    super.key,
  });

  final bool sidebarVisible;
  final VoidCallback onToggleSidebar;
  final String backTooltip;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('gallery-navigation-controls'),
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: sidebarVisible ? 'Hide sidebar' : 'Show sidebar',
        onPressed: onToggleSidebar,
        icon: HugeIcon(
          icon: sidebarVisible
              ? HugeIcons.strokeRoundedSidebarLeft
              : HugeIcons.strokeRoundedPanelLeftOpen,
        ),
      ),
      IconButton(
        tooltip: backTooltip,
        onPressed: onBack,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft02),
      ),
      IconButton(
        tooltip: 'Forward',
        onPressed: onForward,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight02),
      ),
    ],
  );
}
