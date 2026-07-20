import 'package:flutter/material.dart';
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
      padding: EdgeInsets.only(left: 18 + (depth * 14), right: 8, bottom: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.72)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border(
            left: BorderSide(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            selected: selected,
            dense: true,
            contentPadding: const EdgeInsets.only(left: 10, right: 8),
            leading: HugeIcon(
              icon: media.isVideo
                  ? HugeIcons.strokeRoundedVideo01
                  : HugeIcons.strokeRoundedImage01,
              size: 20,
              color: selected ? colorScheme.primary : null,
            ),
            title: Text(
              media.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: selected
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
            trailing: selected
                ? HugeIcon(
                    icon: media.isVideo
                        ? HugeIcons.strokeRoundedPlayCircle
                        : HugeIcons.strokeRoundedView,
                    color: colorScheme.primary,
                    size: 20,
                  )
                : null,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
