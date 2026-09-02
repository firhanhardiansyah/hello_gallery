import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

import '../../../../thumbnail/application/providers/media_dimensions_dependencies.dart';
import '../../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../../../../thumbnail/application/services/thumbnail_job_scheduler.dart';
import '../../../application/providers/gallery_dependencies.dart';
import '../../../application/services/folder_preview_job_scheduler.dart';
import '../../../domain/entities/gallery_item.dart';
import '../../../domain/value_objects/gallery_item_extent.dart';
import '../../../domain/value_objects/gallery_layout_mode.dart';
import '../../states/gallery_ui_state.dart';
import '../../states/media_drag_payload.dart';
import 'gallery_card.dart';

typedef GallerySelectionChanged =
    void Function(int index, {required bool toggle, required bool extend});
typedef MediaFolderDrop =
    void Function(MediaDragPayload payload, String destinationPath);

abstract final class _GalleryGridLayout {
  static const padding = AppSpacing.md;
  static const childAspectRatio = 1.0;
  static const masonryMinimumWarmupItemCount = 12;
  static const masonryDefaultWarmupItemCount = 24;
  static const masonryMaximumWarmupItemCount = 48;
  static const masonryMaximumLandscapeAspectRatio = 4 / 3;
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
    this.layoutMode = GalleryLayoutMode.grid,
    this.maxCrossAxisExtent = GalleryItemExtent.defaultValue,
    this.gridSpacing = AppSpacing.xs,
    this.cardCornerRadius = AppSpacing.sm,
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
  final GalleryLayoutMode layoutMode;
  final double maxCrossAxisExtent;
  final double gridSpacing;
  final double cardCornerRadius;
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
  final _itemKeys = <String, GlobalKey>{};
  int _reportedColumnCount = 1;
  double _itemCrossAxisExtent = 0;
  double _itemMainExtent = 0;
  bool _isScrolling = false;
  bool? _pendingScrollingState;
  bool _scrollingStateUpdateScheduled = false;
  String? _preparedMasonryIdentity;

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
    if (oldWidget.state.currentPath != widget.state.currentPath ||
        oldWidget.layoutMode != widget.layoutMode ||
        (oldWidget.state.loadState is! GalleryLoading &&
            widget.state.loadState is GalleryLoading)) {
      _preparedMasonryIdentity = null;
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
    }
    if (oldWidget.state.currentPath != widget.state.currentPath ||
        oldWidget.state.loadState != widget.state.loadState) {
      _resumePreviewSchedulersImmediately();
    }
    final visiblePaths = widget.state.visibleItems
        .map((item) => item.path)
        .toSet();
    _itemKeys.removeWhere((path, _) => !visiblePaths.contains(path));
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
      _scheduleScrollingStateUpdate(true);
    } else if (notification is ScrollEndNotification) {
      _thumbnailScheduler.setScrolling(false);
      _folderPreviewScheduler.setScrolling(false);
      _scheduleScrollingStateUpdate(false);
    }
    return false;
  }

  void _scheduleScrollingStateUpdate(bool isScrolling) {
    _pendingScrollingState = isScrolling;
    if (_scrollingStateUpdateScheduled) return;
    _scrollingStateUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollingStateUpdateScheduled = false;
      if (!mounted) return;
      final nextState = _pendingScrollingState;
      _pendingScrollingState = null;
      if (nextState == null || nextState == _isScrolling) return;
      setState(() => _isScrolling = nextState);
    });
  }

  void _revealSelection() {
    if (!mounted || widget.state.visibleItems.isEmpty) return;
    final index = widget.selectedIndex.clamp(
      0,
      widget.state.visibleItems.length - 1,
    );
    if (widget.layoutMode == GalleryLayoutMode.masonry) {
      final itemContext =
          _itemKeys[widget.state.visibleItems[index].path]?.currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(
          itemContext,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
      return;
    }
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    final row = index ~/ _reportedColumnCount;
    final itemTop =
        _GalleryGridLayout.padding +
        row * (_itemMainExtent + widget.gridSpacing);
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
      GalleryInitial() || GalleryLoading() => const _GalleryLoadingSurface(),
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
        if (widget.layoutMode == GalleryLayoutMode.masonry &&
            _isPreparingMasonry(visibleItems, constraints)) {
          return const _GalleryLoadingSurface();
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onClearSelection,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: _buildGrid(visibleItems),
          ),
        );
      },
    );
  }

  bool _isPreparingMasonry(
    List<GalleryItem> visibleItems,
    BoxConstraints constraints,
  ) {
    final warmupItemCount = _masonryWarmupItemCount(constraints);
    final warmupItems = visibleItems
        .take(warmupItemCount)
        .whereType<MediaItem>()
        .toList();
    final identity = Object.hashAll([
      widget.state.currentPath,
      for (final item in warmupItems)
        Object.hash(item.path, item.modifiedAt, item.sizeBytes),
    ]).toString();
    if (_preparedMasonryIdentity == identity) return false;
    final dimensions = [
      for (final item in warmupItems) ref.watch(mediaAspectRatioProvider(item)),
    ];
    final isPreparing = dimensions.any(
      (dimension) => !dimension.hasValue && !dimension.hasError,
    );
    if (!isPreparing) _preparedMasonryIdentity = identity;
    return isPreparing;
  }

  int _masonryWarmupItemCount(BoxConstraints constraints) {
    if (!constraints.hasBoundedHeight || _itemCrossAxisExtent <= 0) {
      return _GalleryGridLayout.masonryDefaultWarmupItemCount;
    }
    final minimumItemHeight =
        _itemCrossAxisExtent /
        _GalleryGridLayout.masonryMaximumLandscapeAspectRatio;
    final bufferedRows =
        (constraints.maxHeight / (minimumItemHeight + widget.gridSpacing))
            .ceil() +
        2;
    return (_reportedColumnCount * bufferedRows).clamp(
      _GalleryGridLayout.masonryMinimumWarmupItemCount,
      _GalleryGridLayout.masonryMaximumWarmupItemCount,
    );
  }

  Widget _buildGrid(List<GalleryItem> visibleItems) {
    final key = PageStorageKey<String>(
      'gallery-grid:${widget.state.currentPath}:${widget.layoutMode.name}',
    );
    if (widget.layoutMode == GalleryLayoutMode.masonry) {
      return MasonryGridView.count(
        key: key,
        controller: widget.scrollController,
        padding: const EdgeInsets.all(_GalleryGridLayout.padding),
        crossAxisCount: _reportedColumnCount,
        mainAxisSpacing: widget.gridSpacing,
        crossAxisSpacing: widget.gridSpacing,
        addAutomaticKeepAlives: false,
        itemCount: visibleItems.length,
        itemBuilder: (context, index) =>
            _buildItem(context, index, visibleItems),
      );
    }
    if (widget.layoutMode == GalleryLayoutMode.quilted &&
        _reportedColumnCount > 1) {
      return GridView.custom(
        key: key,
        controller: widget.scrollController,
        padding: const EdgeInsets.all(_GalleryGridLayout.padding),
        scrollCacheExtent: const ScrollCacheExtent.pixels(240),
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: _reportedColumnCount,
          mainAxisSpacing: widget.gridSpacing,
          crossAxisSpacing: widget.gridSpacing,
          repeatPattern: QuiltedGridRepeatPattern.inverted,
          pattern: _quiltedPattern(_reportedColumnCount),
        ),
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) => _buildItem(context, index, visibleItems),
          childCount: visibleItems.length,
          addAutomaticKeepAlives: false,
        ),
      );
    }
    return GridView.builder(
      key: key,
      controller: widget.scrollController,
      padding: const EdgeInsets.all(_GalleryGridLayout.padding),
      addAutomaticKeepAlives: false,
      scrollCacheExtent: const ScrollCacheExtent.pixels(240),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: widget.maxCrossAxisExtent,
        childAspectRatio: _GalleryGridLayout.childAspectRatio,
        mainAxisExtent: _itemMainExtent,
        crossAxisSpacing: widget.gridSpacing,
        mainAxisSpacing: widget.gridSpacing,
      ),
      itemCount: visibleItems.length,
      itemBuilder: (context, index) => _buildItem(context, index, visibleItems),
    );
  }

  List<QuiltedGridTile> _quiltedPattern(int columns) {
    if (columns == 2) {
      return const [
        QuiltedGridTile(2, 2),
        QuiltedGridTile(1, 1),
        QuiltedGridTile(1, 1),
      ];
    }
    return [
      const QuiltedGridTile(2, 2),
      for (var index = 0; index < columns * 2 - 4; index++)
        const QuiltedGridTile(1, 1),
    ];
  }

  void _updateGridMetrics(double availableWidth) {
    final gridWidth = availableWidth - _GalleryGridLayout.padding * 2;
    final columns =
        (gridWidth / (widget.maxCrossAxisExtent + widget.gridSpacing))
            .ceil()
            .clamp(1, 1000);
    _itemCrossAxisExtent =
        (gridWidth - widget.gridSpacing * (columns - 1)) / columns;
    _itemMainExtent =
        _itemCrossAxisExtent / _GalleryGridLayout.childAspectRatio +
        (widget.showItemNames &&
                widget.layoutMode != GalleryLayoutMode.quilted
            ? GalleryCard.itemNameExtent
            : 0);
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
    return KeyedSubtree(
      key: _itemKeys.putIfAbsent(item.path, GlobalKey.new),
      child: ExcludeFocus(
        child: GalleryCard(
          key: ValueKey(item.path),
          item: item,
          selected: selected,
          focused: focused,
          showItemName: widget.showItemNames,
          cornerRadius: widget.cardCornerRadius,
          preserveMediaAspectRatio:
              widget.layoutMode == GalleryLayoutMode.aspectRatioGrid,
          useOriginalAspectRatio:
              widget.layoutMode == GalleryLayoutMode.masonry,
          deferAspectRatioUpdates:
              widget.layoutMode == GalleryLayoutMode.masonry && _isScrolling,
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
              ? () => widget.onSelectionChanged(
                  index,
                  toggle: false,
                  extend: false,
                )
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
      ),
    );
  }
}

class _GalleryLoadingSurface extends StatefulWidget {
  const _GalleryLoadingSurface();

  @override
  State<_GalleryLoadingSurface> createState() => _GalleryLoadingSurfaceState();
}

class _GalleryLoadingSurfaceState extends State<_GalleryLoadingSurface> {
  static const _indicatorDelay = Duration(milliseconds: 120);
  static const _fadeDuration = Duration(milliseconds: 120);
  Timer? _showTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _showTimer = Timer(_indicatorDelay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const SizedBox.expand(),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: AnimatedOpacity(
          duration: _fadeDuration,
          opacity: _visible ? 1 : 0,
          child: const LinearProgressIndicator(
            key: ValueKey('gallery-loading-progress'),
            minHeight: 2,
          ),
        ),
      ),
    ],
  );
}
