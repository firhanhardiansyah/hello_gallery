import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../thumbnail/application/providers/thumbnail_dependencies.dart';

const _galleryCardBorderRadius = BorderRadius.all(Radius.circular(8));

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
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: _galleryCardBorderRadius,
        side: BorderSide(
          color: selected ? colorScheme.primary : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: _galleryCardBorderRadius,
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
    return ClipRRect(
      borderRadius: _galleryCardBorderRadius,
      child: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    if (item case final GalleryFolder folder) {
      if (folder.previewItems.isEmpty) {
        return ColoredBox(
          color: context.appColors.mediaPlaceholder,
          child: const Center(
            child: HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 52),
          ),
        );
      }
      return _FolderPreviewLayout(items: folder.previewItems);
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
                cacheWidth: 320,
                errorBuilder: (_, _, _) => const _VideoPlaceholder(),
              ),
        loading: () => const _VideoPlaceholder(),
        error: (_, _) => const _VideoPlaceholder(),
      );
    }
    return const _VideoPlaceholder();
  }
}

class _FolderPreviewLayout extends StatelessWidget {
  const _FolderPreviewLayout({required this.items});

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    final previews = items.take(4).toList();
    final tiles = [
      for (final item in previews)
        _FolderMediaPreview(
          key: ValueKey('folder-preview:${item.path}'),
          item: item,
        ),
    ];
    return switch (tiles.length) {
      1 => tiles.single,
      2 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final tile in tiles) Expanded(child: tile)],
      ),
      3 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tiles.first),
          Expanded(child: _buildRow(tiles.skip(1))),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildRow(tiles.take(2))),
          Expanded(child: _buildRow(tiles.skip(2))),
        ],
      ),
    };
  }

  Widget _buildRow(Iterable<Widget> tiles) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (final tile in tiles) Expanded(child: tile)],
  );
}

class _FolderMediaPreview extends ConsumerWidget {
  const _FolderMediaPreview({required this.item, super.key});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!item.isVideo) {
      return Image.file(
        File(item.path),
        fit: BoxFit.cover,
        cacheWidth: 240,
        errorBuilder: (_, _, _) => const Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedImageNotFound01,
            size: 28,
          ),
        ),
      );
    }
    final thumbnail = ref.watch(videoThumbnailProvider(item));
    return thumbnail.when(
      data: (thumbnailPath) => thumbnailPath == null
          ? const _VideoPlaceholder(compact: true)
          : Image.file(
              File(thumbnailPath),
              fit: BoxFit.cover,
              cacheWidth: 160,
              errorBuilder: (_, _, _) => const _VideoPlaceholder(compact: true),
            ),
      loading: () => const _VideoPlaceholder(compact: true),
      error: (_, _) => const _VideoPlaceholder(compact: true),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.appColors.mediaPlaceholder,
    child: Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedPlayCircle,
        size: compact ? 28 : 58,
      ),
    ),
  );
}
