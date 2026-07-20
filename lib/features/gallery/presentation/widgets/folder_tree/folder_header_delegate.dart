import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class FolderHeaderDelegate extends SliverPersistentHeaderDelegate {
  FolderHeaderDelegate({
    required this.depth,
    required this.name,
    required this.selected,
    required this.expanded,
    required this.loading,
    required this.surfaceColor,
    required this.overlappingSurfaceColor,
    required this.primaryColor,
    required this.foregroundColor,
    required this.onToggle,
    required this.onOpen,
  });

  final int depth;
  final String name;
  final bool selected;
  final bool expanded;
  final bool loading;
  final Color surfaceColor;
  final Color overlappingSurfaceColor;
  final Color primaryColor;
  final Color foregroundColor;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: Material(
        color: overlapsContent ? overlappingSurfaceColor : surfaceColor,
        elevation: overlapsContent ? 2 : 0,
        child: Padding(
          padding: EdgeInsets.only(left: 8 + (depth * 14), right: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: expanded ? 'Collapse folder' : 'Expand folder',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : HugeIcon(
                        icon: expanded
                            ? HugeIcons.strokeRoundedArrowDown01
                            : HugeIcons.strokeRoundedArrowRight01,
                        color: foregroundColor,
                      ),
              ),
              HugeIcon(
                icon: expanded
                    ? HugeIcons.strokeRoundedFolderOpen
                    : HugeIcons.strokeRoundedFolder01,
                size: 20,
                color: selected ? primaryColor : foregroundColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onOpen ?? onToggle,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: selected
                          ? TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant FolderHeaderDelegate oldDelegate) {
    return depth != oldDelegate.depth ||
        name != oldDelegate.name ||
        selected != oldDelegate.selected ||
        expanded != oldDelegate.expanded ||
        loading != oldDelegate.loading ||
        surfaceColor != oldDelegate.surfaceColor ||
        overlappingSurfaceColor != oldDelegate.overlappingSurfaceColor ||
        primaryColor != oldDelegate.primaryColor ||
        foregroundColor != oldDelegate.foregroundColor;
  }
}
