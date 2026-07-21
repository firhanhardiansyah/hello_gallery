import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

import '../../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../../../../thumbnail/application/services/thumbnail_job_scheduler.dart';
import '../../../application/providers/gallery_dependencies.dart';
import '../../../application/services/folder_preview_job_scheduler.dart';
import '../../../domain/entities/gallery_item.dart';
import '../../states/gallery_ui_state.dart';
import '../gallery_card.dart';

class GalleryBody extends ConsumerStatefulWidget {
  const GalleryBody({
    required this.state,
    required this.scrollController,
    required this.selectedIndex,
    required this.onSelectionChanged,
    required this.onColumnCountChanged,
    required this.onFolderSelected,
    required this.onMediaSelected,
    this.onRenameFolder,
    this.onDeleteFolder,
    super.key,
  });

  final GalleryUiState state;
  final ScrollController scrollController;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;
  final ValueChanged<int> onColumnCountChanged;
  final ValueChanged<String> onFolderSelected;
  final ValueChanged<MediaItem> onMediaSelected;
  final ValueChanged<String>? onRenameFolder;
  final ValueChanged<String>? onDeleteFolder;

  @override
  ConsumerState<GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends ConsumerState<GalleryBody> {
  static const _gridPadding = AppSpacing.lg;
  static const _itemMainExtent = 210.0;
  static const _mainAxisSpacing = AppSpacing.md;

  late final ThumbnailJobScheduler _thumbnailScheduler;
  late final FolderPreviewJobScheduler _folderPreviewScheduler;
  int _reportedColumnCount = 1;

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
        oldWidget.state.status != widget.state.status) {
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
    final itemTop = _gridPadding + row * (_itemMainExtent + _mainAxisSpacing);
    final itemBottom = itemTop + _itemMainExtent;
    final viewportTop = position.pixels;
    final viewportBottom = viewportTop + position.viewportDimension;
    if (itemTop >= viewportTop && itemBottom <= viewportBottom) return;
    final target = itemTop < viewportTop
        ? itemTop - _gridPadding
        : itemBottom - position.viewportDimension + _gridPadding;
    widget.scrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.state.status) {
      GalleryStatus.initial || GalleryStatus.loading => const _LoadingGrid(),
      GalleryStatus.empty => const Center(
        child: Text('No supported media in this folder.'),
      ),
      GalleryStatus.error => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Could not read this folder.\n${widget.state.errorMessage}',
          ),
        ),
      ),
      GalleryStatus.ready => _buildReadyGrid(),
    };
  }

  Widget _buildReadyGrid() {
    final visibleItems = widget.state.visibleItems;
    return LayoutBuilder(
      builder: (context, constraints) {
        _reportColumnCount(constraints.maxWidth);
        return NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: GridView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(_gridPadding),
            addAutomaticKeepAlives: false,
            cacheExtent: 240,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: _itemMainExtent,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: _mainAxisSpacing,
            ),
            itemCount: visibleItems.length,
            itemBuilder: (context, index) =>
                _buildItem(context, index, visibleItems),
          ),
        );
      },
    );
  }

  void _reportColumnCount(double availableWidth) {
    final columns = ((availableWidth - 20) / 272).ceil().clamp(1, 1000);
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
    return ExcludeFocus(
      child: GalleryCard(
        key: ValueKey(item.path),
        item: item,
        selected: index == widget.selectedIndex,
        onRenameFolder: item is GalleryFolder && widget.onRenameFolder != null
            ? () => widget.onRenameFolder!(item.path)
            : null,
        onDeleteFolder: item is GalleryFolder && widget.onDeleteFolder != null
            ? () => widget.onDeleteFolder!(item.path)
            : null,
        onTap: () {
          widget.onSelectionChanged(index);
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 210,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: 18,
      itemBuilder: (_, _) =>
          Card(child: ColoredBox(color: appColors.loadingPlaceholder)),
    );
  }
}
