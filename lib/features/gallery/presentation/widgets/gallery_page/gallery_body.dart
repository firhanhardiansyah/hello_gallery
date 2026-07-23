import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

import '../../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../../../../thumbnail/application/services/thumbnail_job_scheduler.dart';
import '../../../application/providers/gallery_dependencies.dart';
import '../../../application/services/folder_preview_job_scheduler.dart';
import '../../../domain/entities/gallery_item.dart';
import '../../states/gallery_ui_state.dart';
import '../../states/media_drag_payload.dart';
import 'gallery_card.dart';

typedef GallerySelectionChanged =
    void Function(int index, {required bool toggle, required bool extend});
typedef MediaFolderDrop =
    void Function(MediaDragPayload payload, String destinationPath);

abstract final class _GalleryGridLayout {
  static const padding = AppSpacing.md;
  static const spacing = AppSpacing.xs;
  static const maxCrossAxisExtent = 260.0;
  static const childAspectRatio = 3 / 4;
}

class GalleryBody extends ConsumerStatefulWidget {
  const GalleryBody({
    required this.state,
    required this.scrollController,
    required this.selectedIndex,
    this.keyboardFocusVisible = false,
    required this.selectedPaths,
    required this.onSelectionChanged,
    required this.onClearSelection,
    required this.onColumnCountChanged,
    required this.onFolderSelected,
    required this.onMediaSelected,
    required this.onMediaDropped,
    this.showItemNames = true,
    this.onRenameFolder,
    this.onDeleteFolder,
    this.onRenameMedia,
    this.onDeleteMedia,
    super.key,
  });

  final GalleryUiState state;
  final ScrollController scrollController;
  final int selectedIndex;
  final bool keyboardFocusVisible;
  final Set<String> selectedPaths;
  final GallerySelectionChanged onSelectionChanged;
  final VoidCallback onClearSelection;
  final ValueChanged<int> onColumnCountChanged;
  final ValueChanged<String> onFolderSelected;
  final ValueChanged<MediaItem> onMediaSelected;
  final MediaFolderDrop onMediaDropped;
  final bool showItemNames;
  final ValueChanged<String>? onRenameFolder;
  final ValueChanged<String>? onDeleteFolder;
  final ValueChanged<MediaItem>? onRenameMedia;
  final ValueChanged<List<MediaItem>>? onDeleteMedia;

  @override
  ConsumerState<GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends ConsumerState<GalleryBody> {
  late final ThumbnailJobScheduler _thumbnailScheduler;
  late final FolderPreviewJobScheduler _folderPreviewScheduler;
  int _reportedColumnCount = 1;
  double _itemMainExtent = 0;

  @override
  void initState() {
    super.initState();
    _thumbnailScheduler = ref.read(thumbnailJobSchedulerProvider);
    _folderPreviewScheduler = ref.read(folderPreviewJobSchedulerProvider);
    _resumePreviewSchedulersImmediately();
  }

  @override
  void didUpdateWidget(covariant GalleryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
    }
    if (oldWidget.state.currentPath != widget.state.currentPath ||
        oldWidget.state.loadState != widget.state.loadState) {
      _resumePreviewSchedulersImmediately();
    }
  }

  @override
  void dispose() {
    _resumePreviewSchedulersImmediately();
    super.dispose();
  }

  void _resumePreviewSchedulersImmediately() {
    _thumbnailScheduler.resumeImmediately();
    _folderPreviewScheduler.resumeImmediately();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _thumbnailScheduler.setScrolling(true);
      _folderPreviewScheduler.setScrolling(true);
    } else if (notification is ScrollEndNotification) {
      _thumbnailScheduler.setScrolling(false);
      _folderPreviewScheduler.setScrolling(false);
    }
    return false;
  }

  void _revealSelection() {
    if (!mounted || widget.state.visibleItems.isEmpty) return;
    final index = widget.selectedIndex.clamp(
      0,
      widget.state.visibleItems.length - 1,
    );
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    final row = index ~/ _reportedColumnCount;
    final itemTop =
        _GalleryGridLayout.padding +
        row * (_itemMainExtent + _GalleryGridLayout.spacing);
    final itemBottom = itemTop + _itemMainExtent;
    final viewportTop = position.pixels;
    final viewportBottom = viewportTop + position.viewportDimension;
    if (itemTop >= viewportTop && itemBottom <= viewportBottom) return;
    final target = itemTop < viewportTop
        ? itemTop - _GalleryGridLayout.padding
        : itemBottom - position.viewportDimension + _GalleryGridLayout.padding;
    widget.scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.state.loadState) {
      GalleryInitial() || GalleryLoading() => const _LoadingGrid(),
      GalleryEmpty() => const Center(
        child: Text('No supported media in this folder.'),
      ),
      GalleryError(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text('Could not read this folder.\n$message'),
        ),
      ),
      GalleryReady() => _buildReadyGrid(),
    };
  }

  Widget _buildReadyGrid() {
    final visibleItems = widget.state.visibleItems;
    return LayoutBuilder(
      builder: (context, constraints) {
        _updateGridMetrics(constraints.maxWidth);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onClearSelection,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: GridView.builder(
              key: PageStorageKey<String>(
                'gallery-grid:${widget.state.currentPath}',
              ),
              controller: widget.scrollController,
              padding: const EdgeInsets.all(_GalleryGridLayout.padding),
              addAutomaticKeepAlives: false,
              cacheExtent: 240,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: _GalleryGridLayout.maxCrossAxisExtent,
                childAspectRatio: _GalleryGridLayout.childAspectRatio,
                crossAxisSpacing: _GalleryGridLayout.spacing,
                mainAxisSpacing: _GalleryGridLayout.spacing,
              ),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) =>
                  _buildItem(context, index, visibleItems),
            ),
          ),
        );
      },
    );
  }

  void _updateGridMetrics(double availableWidth) {
    final gridWidth = availableWidth - _GalleryGridLayout.padding * 2;
    final columns =
        (gridWidth /
                (_GalleryGridLayout.maxCrossAxisExtent +
                    _GalleryGridLayout.spacing))
            .ceil()
            .clamp(1, 1000);
    final itemCrossAxisExtent =
        (gridWidth - _GalleryGridLayout.spacing * (columns - 1)) / columns;
    _itemMainExtent = itemCrossAxisExtent / _GalleryGridLayout.childAspectRatio;
    if (columns == _reportedColumnCount) return;
    _reportedColumnCount = columns;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onColumnCountChanged(columns);
    });
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    List<GalleryItem> visibleItems,
  ) {
    final item = visibleItems[index];
    final selected = widget.selectedPaths.contains(item.path);
    final focused =
        widget.keyboardFocusVisible && widget.selectedIndex == index;
    final dragPayload = item is MediaItem
        ? MediaDragPayload(
            selected
                ? [
                    item,
                    for (final candidate in visibleItems.whereType<MediaItem>())
                      if (candidate.path != item.path &&
                          widget.selectedPaths.contains(candidate.path))
                        candidate,
                  ]
                : [item],
          )
        : null;
    final selectedMedia = [
      for (final candidate in visibleItems.whereType<MediaItem>())
        if (widget.selectedPaths.contains(candidate.path)) candidate,
    ];
    final mediaDeleteTargets = item is MediaItem
        ? selected
              ? selectedMedia
              : [item]
        : const <MediaItem>[];
    return ExcludeFocus(
      child: GalleryCard(
        key: ValueKey(item.path),
        item: item,
        selected: selected,
        focused: focused,
        showItemName: widget.showItemNames,
        onRenameFolder: item is GalleryFolder && widget.onRenameFolder != null
            ? () => widget.onRenameFolder!(item.path)
            : null,
        onDeleteFolder: item is GalleryFolder && widget.onDeleteFolder != null
            ? () => widget.onDeleteFolder!(item.path)
            : null,
        onRenameMedia:
            item is MediaItem &&
                widget.onRenameMedia != null &&
                (!selected || widget.selectedPaths.length == 1)
            ? () => widget.onRenameMedia!(item)
            : null,
        onDeleteMedia: item is MediaItem && widget.onDeleteMedia != null
            ? () => widget.onDeleteMedia!(mediaDeleteTargets)
            : null,
        onMediaContextMenuOpened: item is MediaItem && !selected
            ? () =>
                  widget.onSelectionChanged(index, toggle: false, extend: false)
            : null,
        dragPayload: dragPayload,
        onDragStarted: () {
          if (!selected) {
            widget.onSelectionChanged(index, toggle: false, extend: false);
          }
        },
        onMediaDropped: item is GalleryFolder
            ? (payload) => widget.onMediaDropped(payload, item.path)
            : null,
        onTap: () {
          final keyboard = HardwareKeyboard.instance;
          final toggle = keyboard.isControlPressed || keyboard.isMetaPressed;
          final extend = keyboard.isShiftPressed;
          if (toggle || extend) {
            widget.onSelectionChanged(index, toggle: toggle, extend: extend);
            return;
          }
          if (widget.selectedPaths.isNotEmpty) {
            widget.onSelectionChanged(index, toggle: true, extend: false);
            return;
          }
          widget.onClearSelection();
          switch (item) {
            case GalleryFolder():
              widget.onFolderSelected(item.path);
            case MediaItem():
              widget.onMediaSelected(item);
          }
        },
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return GridView.builder(
      padding: const EdgeInsets.all(_GalleryGridLayout.padding),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _GalleryGridLayout.maxCrossAxisExtent,
        childAspectRatio: _GalleryGridLayout.childAspectRatio,
        crossAxisSpacing: _GalleryGridLayout.spacing,
        mainAxisSpacing: _GalleryGridLayout.spacing,
      ),
      itemCount: 18,
      itemBuilder: (_, _) => ColoredBox(color: appColors.loadingPlaceholder),
    );
  }
}
