import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

class FolderHeaderDelegate extends SliverPersistentHeaderDelegate {
  FolderHeaderDelegate({
    required this.depth,
    required this.name,
    required this.selected,
    required this.expanded,
    required this.loading,
    required this.itemCount,
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
  final int? itemCount;
  final Color surfaceColor;
  final Color overlappingSurfaceColor;
  final Color primaryColor;
  final Color foregroundColor;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

  @override
  double get minExtent => 36;

  @override
  double get maxExtent => 36;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Material(
        color: overlapsContent ? overlappingSurfaceColor : surfaceColor,
        elevation: overlapsContent ? 2 : 0,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.sm + (depth * 14),
            right: AppSpacing.md,
          ),
          child: InkWell(
            onTap: onOpen ?? onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                _buildToggle(),
                HugeIcon(
                  icon: expanded
                      ? HugeIcons.strokeRoundedFolderOpen
                      : HugeIcons.strokeRoundedFolder01,
                  size: 20,
                  color: selected ? primaryColor : foregroundColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
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
                if (itemCount case final count?) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Badge.count(
                      count: count,
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    if (loading) {
      return const SizedBox.square(
        dimension: 40,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: expanded ? 'Collapse folder' : 'Expand folder',
      visualDensity: VisualDensity.compact,
      onPressed: onToggle,
      icon: HugeIcon(
        icon: expanded
            ? HugeIcons.strokeRoundedArrowDown01
            : HugeIcons.strokeRoundedArrowRight01,
        color: foregroundColor,
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
        itemCount != oldDelegate.itemCount ||
        surfaceColor != oldDelegate.surfaceColor ||
        overlappingSurfaceColor != oldDelegate.overlappingSurfaceColor ||
        primaryColor != oldDelegate.primaryColor ||
        foregroundColor != oldDelegate.foregroundColor;
  }
}
