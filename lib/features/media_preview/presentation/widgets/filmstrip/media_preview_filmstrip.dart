import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/thumbnail/application/providers/thumbnail_dependencies.dart';
import 'package:hugeicons/hugeicons.dart';

import 'media_preview_filmstrip_controller.dart';

class MediaPreviewFilmstrip extends StatefulWidget {
  const MediaPreviewFilmstrip({
    required this.items,
    required this.activeIndex,
    required this.visible,
    required this.bottomInset,
    required this.controller,
    required this.onSelected,
    super.key,
  });

  static const overlayHeight = 96.0;

  final List<MediaItem> items;
  final int activeIndex;
  final bool visible;
  final double bottomInset;
  final MediaPreviewFilmstripController controller;
  final ValueChanged<int> onSelected;

  @override
  State<MediaPreviewFilmstrip> createState() => _MediaPreviewFilmstripState();
}

class _MediaPreviewFilmstripState extends State<MediaPreviewFilmstrip> {
  Timer? _removeTimer;
  late bool _buildSurface;

  @override
  void initState() {
    super.initState();
    _buildSurface = widget.visible;
  }

  @override
  void didUpdateWidget(covariant MediaPreviewFilmstrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    _removeTimer?.cancel();
    if (widget.visible) {
      _buildSurface = true;
      return;
    }
    _removeTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && !widget.visible) setState(() => _buildSurface = false);
    });
  }

  @override
  void dispose() {
    _removeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: AppSpacing.lg,
    right: AppSpacing.lg,
    bottom: widget.bottomInset,
    height: MediaPreviewFilmstrip.overlayHeight,
    child: IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        offset: widget.visible ? Offset.zero : const Offset(0, 0.3),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.visible ? 1 : 0,
          child: _buildSurface
              ? _FilmstripSurface(
                  items: widget.items,
                  activeIndex: widget.activeIndex,
                  controller: widget.controller,
                  onSelected: widget.onSelected,
                )
              : const SizedBox(key: ValueKey('media-preview-filmstrip-hidden')),
        ),
      ),
    ),
  );
}

class _FilmstripSurface extends StatelessWidget {
  const _FilmstripSurface({
    required this.items,
    required this.activeIndex,
    required this.controller,
    required this.onSelected,
  });

  final List<MediaItem> items;
  final int activeIndex;
  final MediaPreviewFilmstripController controller;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.mediaControlSurface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.appColors.onMediaMuted.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Listener(
          onPointerSignal: controller.handlePointerSignal,
          child: ListView.builder(
            key: const ValueKey('media-preview-filmstrip-list'),
            controller: controller.scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: MediaPreviewFilmstripController.horizontalPadding,
              vertical: AppSpacing.sm,
            ),
            itemExtent: MediaPreviewFilmstripController.itemExtent,
            itemCount: items.length,
            itemBuilder: (context, index) => Align(
              alignment: Alignment.centerLeft,
              child: _FilmstripItem(
                item: items[index],
                selected: index == activeIndex,
                onTap: () => onSelected(index),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FilmstripItem extends StatelessWidget {
  const _FilmstripItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      key: ValueKey('filmstrip-semantics:${item.path}'),
      button: true,
      selected: selected,
      label: item.name,
      child: Tooltip(
        message: item.name,
        child: GestureDetector(
          key: ValueKey('filmstrip-item:${item.path}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: MediaPreviewFilmstripController.thumbnailWidth,
            height: MediaPreviewFilmstripController.thumbnailHeight,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected ? colorScheme.primary : Colors.transparent,
                width: selected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _FilmstripThumbnail(item: item),
                  if (item.isVideo)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: context.appColors.mediaOverlay,
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          size: 12,
                          color: context.appColors.onMedia,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilmstripThumbnail extends ConsumerWidget {
  const _FilmstripThumbnail({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!item.isVideo) {
      return Image.file(
        File(item.path),
        fit: BoxFit.contain,
        cacheWidth: 176,
        cacheHeight: 128,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }

    final thumbnailPath = ref.watch(videoThumbnailProvider(item)).value;
    if (thumbnailPath == null) return _placeholder(context);
    return Image.file(
      File(thumbnailPath),
      fit: BoxFit.contain,
      cacheWidth: 176,
      cacheHeight: 128,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) => ColoredBox(
    color: context.appColors.mediaPlaceholder,
    child: Center(
      child: HugeIcon(
        icon: item.isVideo
            ? HugeIcons.strokeRoundedFilm01
            : HugeIcons.strokeRoundedImage02,
        size: 24,
        color: context.appColors.onMediaMuted,
      ),
    ),
  );
}
