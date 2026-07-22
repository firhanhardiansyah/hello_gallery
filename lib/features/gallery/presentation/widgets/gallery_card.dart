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

const _galleryCardBorderRadius = BorderRadius.zero;
const _dragFeedbackBorderRadius = BorderRadius.all(Radius.circular(8));

class GalleryCard extends StatelessWidget {
  const GalleryCard({
    required this.item,
    required this.onTap,
    this.onDoubleTap,
    this.selected = false,
    this.focused = false,
    this.showItemName = true,
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
  final bool focused;
  final bool showItemName;
  final VoidCallback? onRenameFolder;
  final VoidCallback? onDeleteFolder;
  final MediaDragPayload? dragPayload;
  final VoidCallback? onDragStarted;
  final ValueChanged<MediaDragPayload>? onMediaDropped;

  @override
  Widget build(BuildContext context) {
    Widget buildCard({bool dropHighlighted = false}) => _GalleryCardSurface(
      item: item,
      selected: selected,
      focused: focused,
      showItemName: showItemName,
      dropHighlighted: dropHighlighted,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
    );

    Widget withFolderContextMenu(Widget child) {
      if (item is! GalleryFolder ||
          onRenameFolder == null ||
          onDeleteFolder == null) {
        return child;
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => showFolderContextMenu(
          context: context,
          globalPosition: details.globalPosition,
          onRename: onRenameFolder!,
          onMoveToTrash: onDeleteFolder!,
        ),
        child: child,
      );
    }

    Widget result = withFolderContextMenu(buildCard());
    if (item case final GalleryFolder folder when onMediaDropped != null) {
      result = DragTarget<MediaDragPayload>(
        onWillAcceptWithDetails: (details) => details.data.items.any(
          (media) => !path.equals(path.dirname(media.path), folder.path),
        ),
        onAcceptWithDetails: (details) => onMediaDropped!(details.data),
        builder: (context, candidates, rejected) => withFolderContextMenu(
          buildCard(dropHighlighted: candidates.isNotEmpty),
        ),
      );
    }
    final payload = dragPayload;
    if (item is MediaItem && payload != null) {
      result = LongPressDraggable<MediaDragPayload>(
        data: payload,
        delay: const Duration(milliseconds: 300),
        hapticFeedbackOnStart: false,
        rootOverlay: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: onDragStarted,
        feedback: Transform.translate(
          offset: const Offset(AppSpacing.md, AppSpacing.md),
          child: _MediaDragFeedback(items: payload.items),
        ),
        childWhenDragging: Opacity(opacity: 0.45, child: result),
        child: result,
      );
    }
    return result;
  }
}

class _GalleryCardSurface extends StatelessWidget {
  const _GalleryCardSurface({
    required this.item,
    required this.selected,
    required this.focused,
    required this.showItemName,
    required this.dropHighlighted,
    required this.onTap,
    required this.onDoubleTap,
  });

  final GalleryItem item;
  final bool selected;
  final bool focused;
  final bool showItemName;
  final bool dropHighlighted;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: _galleryCardBorderRadius,
      ),
      child: InkWell(
        borderRadius: _galleryCardBorderRadius,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                key: const ValueKey('gallery-card-preview'),
                fit: StackFit.expand,
                children: [
                  _Preview(item: item),
                  if (selected)
                    _PreviewBorder(
                      key: const ValueKey('gallery-card-selection-border'),
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.08,
                      ),
                    )
                  else if (focused)
                    _PreviewBorder(
                      key: const ValueKey('gallery-card-focus-border'),
                      color: colorScheme.primary,
                    ),
                  if (dropHighlighted)
                    _PreviewBorder(
                      key: const ValueKey('gallery-card-drop-border'),
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  if (selected)
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
              ),
            ),

            if (showItemName)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.xs,
                ),
                child: Align(
                  child: DecoratedBox(
                    key: const ValueKey('gallery-card-label-background'),
                    decoration: BoxDecoration(
                      color: selected || focused
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        item.name,
                        maxLines: selected || focused ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected || focused
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (showItemName) return surface;
    return Semantics(
      label: item.name,
      button: true,
      excludeSemantics: true,
      child: surface,
    );
  }
}

class _PreviewBorder extends StatelessWidget {
  const _PreviewBorder({required this.color, this.backgroundColor, super.key});

  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: _galleryCardBorderRadius,
        border: Border.all(color: color, width: 2),
      ),
    ),
  );
}

class _MediaDragFeedback extends StatelessWidget {
  const _MediaDragFeedback({required this.items});

  static const _cardWidth = 220.0;
  static const _cardHeight = 175.0;

  static int get _thumbnailCacheWidth => (_cardWidth * 1.5).round();

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    final previews = items.take(3).toList();
    return Material(
      key: const ValueKey('media-drag-feedback'),
      type: MaterialType.transparency,
      child: SizedBox(
        width: _cardWidth + 28,
        height: _cardHeight + 26,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = previews.length - 1; index >= 0; index--)
              Positioned(
                left: _leftOffset(index),
                top: _topOffset(index),
                child: Transform.rotate(
                  angle: _rotation(index),
                  child: SizedBox(
                    width: _cardWidth,
                    height: _cardHeight,
                    child: _DragMediaCard(
                      key: ValueKey('media-drag-preview-$index'),
                      item: previews[index],
                      isFront: index == 0,
                    ),
                  ),
                ),
              ),
            if (items.length > 1)
              Positioned(
                top: 0,
                right: 0,
                child: _DragItemCount(count: items.length),
              ),
          ],
        ),
      ),
    );
  }

  double _rotation(int index) => switch (index) {
    0 => 0,
    1 => -0.08,
    _ => 0.07,
  };

  double _leftOffset(int index) => switch (index) {
    0 => 12,
    1 => 3,
    _ => 15,
  };

  double _topOffset(int index) => switch (index) {
    0 => 13,
    1 => 11,
    _ => 3,
  };
}

class _DragMediaCard extends ConsumerWidget {
  const _DragMediaCard({required this.item, required this.isFront, super.key});

  final MediaItem item;
  final bool isFront;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: isFront ? 10 : 5,
      shadowColor: Colors.black45,
      color: colorScheme.surfaceContainerHighest,
      borderRadius: _dragFeedbackBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(context, ref),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              color: Colors.black.withValues(alpha: 0.64),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, WidgetRef ref) {
    if (!item.isVideo) {
      return Image.file(
        File(item.path),
        fit: BoxFit.cover,
        cacheWidth: _MediaDragFeedback._thumbnailCacheWidth,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => const _DragMediaPlaceholder(
          icon: HugeIcons.strokeRoundedImageNotFound01,
        ),
      );
    }
    return ref
        .watch(cachedVideoThumbnailProvider(item))
        .when(
          data: (thumbnailPath) => thumbnailPath == null
              ? const _DragMediaPlaceholder(
                  icon: HugeIcons.strokeRoundedVideo01,
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(thumbnailPath),
                      fit: BoxFit.cover,
                      cacheWidth: _MediaDragFeedback._thumbnailCacheWidth,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, _, _) => const _DragMediaPlaceholder(
                        icon: HugeIcons.strokeRoundedVideo01,
                      ),
                    ),
                    const Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xs),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedPlay,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          loading: () =>
              const _DragMediaPlaceholder(icon: HugeIcons.strokeRoundedVideo01),
          error: (_, _) =>
              const _DragMediaPlaceholder(icon: HugeIcons.strokeRoundedVideo01),
        );
  }
}

class _DragMediaPlaceholder extends StatelessWidget {
  const _DragMediaPlaceholder({required this.icon});

  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.appColors.mediaPlaceholder,
    child: Center(child: HugeIcon(icon: icon, size: 32)),
  );
}

class _DragItemCount extends StatelessWidget {
  const _DragItemCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('media-drag-count'),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.onPrimary, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
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
