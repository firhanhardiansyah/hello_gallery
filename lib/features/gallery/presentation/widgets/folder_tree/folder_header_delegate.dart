import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../states/media_drag_payload.dart';
import '../folder_management/folder_context_menu.dart';

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
    this.activeIndicatorWidth = defaultActiveIndicatorWidth,
    this.onRename,
    this.onDelete,
    this.canAcceptMedia,
    this.onMediaDropped,
  }) : assert(activeIndicatorWidth > 0);

  static const defaultActiveIndicatorWidth = 3.0;

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
  final double activeIndicatorWidth;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final bool Function(MediaDragPayload payload)? canAcceptMedia;
  final ValueChanged<MediaDragPayload>? onMediaDropped;

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
    final header = SizedBox.expand(
      child: Material(
        color: overlapsContent ? overlappingSurfaceColor : surfaceColor,
        elevation: overlapsContent ? 2 : 0,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.sm + (depth * 14),
            right: AppSpacing.md,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (selected)
                Positioned(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  left: 0,
                  child: SizedBox(
                    key: const ValueKey('active-folder-indicator'),
                    width: activeIndicatorWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: foregroundColor,
                        borderRadius: BorderRadius.circular(
                          activeIndicatorWidth / 2,
                        ),
                      ),
                    ),
                  ),
                ),
              InkWell(
                onTap: onOpen ?? onToggle,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.sm),
                    HugeIcon(
                      icon: expanded
                          ? HugeIcons.strokeRoundedFolder02
                          : HugeIcons.strokeRoundedFolder01,
                      size: 20,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (itemCount case final count?) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
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

                    _buildToggle(color: foregroundColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Widget result = header;
    if (onRename != null && onDelete != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => showFolderContextMenu(
          context: context,
          globalPosition: details.globalPosition,
          onRename: onRename!,
          onMoveToTrash: onDelete!,
        ),
        child: result,
      );
    }
    if (onMediaDropped != null) {
      final folderHeader = result;
      result = DragTarget<MediaDragPayload>(
        onWillAcceptWithDetails: (details) =>
            canAcceptMedia?.call(details.data) ?? true,
        onAcceptWithDetails: (details) => onMediaDropped!(details.data),
        builder: (context, candidates, rejected) => Stack(
          fit: StackFit.expand,
          children: [
            folderHeader,
            if (candidates.isNotEmpty)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.14),
                    border: Border.all(color: primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return result;
  }

  Widget _buildToggle({required Color color}) {
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
        color: color,
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
        foregroundColor != oldDelegate.foregroundColor ||
        activeIndicatorWidth != oldDelegate.activeIndicatorWidth;
  }
}
