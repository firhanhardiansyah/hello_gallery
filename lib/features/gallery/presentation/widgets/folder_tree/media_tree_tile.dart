import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../domain/entities/gallery_item.dart';

class MediaTreeTile extends StatelessWidget {
  const MediaTreeTile({
    required this.media,
    required this.depth,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final MediaItem media;
  final int depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxl + (depth * AppSpacing.lg),
        right: AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            selected: selected,
            dense: true,
            contentPadding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.sm,
            ),
            leading: HugeIcon(
              icon: media.isVideo
                  ? HugeIcons.strokeRoundedVideo01
                  : HugeIcons.strokeRoundedImage01,
              size: 20,
              color: selected ? colorScheme.onPrimaryContainer : null,
            ),
            title: Text(
              media.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: selected
                  ? TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    )
                  : null,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
