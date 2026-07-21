import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as path;

import '../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../../application/providers/gallery_dependencies.dart';
import '../states/media_drag_payload.dart';
import 'folder_management/folder_context_menu.dart';

const _galleryCardBorderRadius = BorderRadius.all(Radius.circular(8));

class GalleryCard extends StatelessWidget {
  const GalleryCard({
    required this.item,
    required this.onTap,
    this.onDoubleTap,
    this.selected = false,
    this.onRenameFolder,
    this.onDeleteFolder,
    this.dragPayload,
    this.onDragStarted,
    this.onMediaDropped,
    super.key,
  });

  final GalleryItem item;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final bool selected;
  final VoidCallback? onRenameFolder;
  final VoidCallback? onDeleteFolder;
  final MediaDragPayload? dragPayload;
  final VoidCallback? onDragStarted;
  final ValueChanged<MediaDragPayload>? onMediaDropped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.24)
              : Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: _galleryCardBorderRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: _galleryCardBorderRadius,
            onTap: onTap,
            onDoubleTap: onDoubleTap,
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
        ),
        if (selected) ...[
          IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('gallery-card-selection-border'),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: _galleryCardBorderRadius,
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('gallery-card-selection-check'),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedTick02,
                    color: colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
    Widget result = card;
    if (item is GalleryFolder &&
        onRenameFolder != null &&
        onDeleteFolder != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => showFolderContextMenu(
          context: context,
          globalPosition: details.globalPosition,
          onRename: onRenameFolder!,
          onMoveToTrash: onDeleteFolder!,
        ),
        child: result,
      );
    }
    if (item case final GalleryFolder folder when onMediaDropped != null) {
      final folderCard = result;
      result = DragTarget<MediaDragPayload>(
        onWillAcceptWithDetails: (details) => details.data.items.any(
          (media) => !path.equals(path.dirname(media.path), folder.path),
        ),
        onAcceptWithDetails: (details) => onMediaDropped!(details.data),
        builder: (context, candidates, rejected) => Stack(
          fit: StackFit.expand,
          children: [
            folderCard,
            if (candidates.isNotEmpty)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: _galleryCardBorderRadius,
                    border: Border.all(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    final payload = dragPayload;
    if (item is MediaItem && payload != null) {
      result = LongPressDraggable<MediaDragPayload>(
        data: payload,
        delay: const Duration(milliseconds: 120),
        hapticFeedbackOnStart: false,
        rootOverlay: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: onDragStarted,
        feedback: _MediaDragFeedback(count: payload.count),
        childWhenDragging: Opacity(opacity: 0.45, child: result),
        child: result,
      );
    }
    return result;
  }
}

class _MediaDragFeedback extends StatelessWidget {
  const _MediaDragFeedback({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    color: Theme.of(context).colorScheme.primaryContainer,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedMove, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(count == 1 ? 'Move media' : 'Move $count media'),
        ],
      ),
    ),
  );
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
      return ref
          .watch(folderPreviewProvider(folder))
          .when(
            data: (items) => items.isEmpty
                ? const _FolderPlaceholder()
                : _FolderPreviewLayout(items: items),
            loading: () => const _FolderPlaceholder(),
            error: (_, _) => const _FolderPlaceholder(),
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

class _FolderPlaceholder extends StatelessWidget {
  const _FolderPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.appColors.mediaPlaceholder,
    child: const Center(
      child: HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 52),
    ),
  );
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
