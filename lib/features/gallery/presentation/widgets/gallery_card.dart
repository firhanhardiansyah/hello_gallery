import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../thumbnail/application/providers/thumbnail_dependencies.dart';

class GalleryCard extends StatelessWidget {
  const GalleryCard({
    required this.item,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final GalleryItem item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const borderRadius = BorderRadius.all(Radius.circular(8));
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: selected ? colorScheme.primary : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Preview(item: item)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item case final GalleryFolder folder) {
      if (folder.previewPaths.isEmpty) {
        return ColoredBox(
          color: context.appColors.mediaPlaceholder,
          child: const Center(
            child: HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 52),
          ),
        );
      }
      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        children: [
          for (final preview in folder.previewPaths)
            Image.file(File(preview), fit: BoxFit.cover, cacheWidth: 240),
        ],
      );
    }
    if (item case final MediaItem media when !media.isVideo) {
      return Image.file(
        File(media.path),
        fit: BoxFit.cover,
        cacheWidth: 420,
        errorBuilder: (_, _, _) => const Center(
          child: HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01),
        ),
      );
    }
    if (item case final MediaItem media) {
      final thumbnail = ref.watch(videoThumbnailProvider(media));
      return thumbnail.when(
        data: (thumbnailPath) => thumbnailPath == null
            ? const _VideoPlaceholder()
            : Image.file(
                File(thumbnailPath),
                fit: BoxFit.cover,
                cacheWidth: 420,
                errorBuilder: (_, _, _) => const _VideoPlaceholder(),
              ),
        loading: () => const _VideoPlaceholder(),
        error: (_, _) => const _VideoPlaceholder(),
      );
    }
    return const _VideoPlaceholder();
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.appColors.mediaPlaceholder,
    child: const Center(
      child: HugeIcon(icon: HugeIcons.strokeRoundedPlayCircle, size: 58),
    ),
  );
}
