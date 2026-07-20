import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hello_gallery/core/utils/natural_compare.dart';
import '../../../../app/routing/app_router.dart';
import '../../../gamepad/presentation/widgets/virtual_cursor_overlay.dart';
import '../../../media_preview/presentation/notifiers/media_preview_notifier.dart';
import '../../../media_preview/presentation/pages/media_preview_page.dart';
import '../../../settings/presentation/notifiers/settings_notifier.dart';
import '../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../../../thumbnail/application/services/thumbnail_job_scheduler.dart';
import '../../application/providers/gallery_dependencies.dart';
import '../notifiers/gallery_notifier.dart';
import '../states/gallery_ui_state.dart';
import '../widgets/folder_tree_sidebar.dart';
import '../widgets/gallery_card.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({this.previewPath, super.key});

  final String? previewPath;

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  final _scrollController = ScrollController();
  String? _loadedRoot;
  bool _sidebarVisible = true;
  _MediaPreviewSelection? _preview;
  bool _isFullscreen = false;
  bool? _sidebarBeforeFullscreen;
  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;
  int _selectedGridIndex = 0;
  int _gridColumnCount = 1;
  int _previewLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGalleryKey);
    _gamepadSubscription = Gamepads.normalizedEvents.listen(
      _handleGalleryGamepad,
    );
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 600) {
        ref.read(galleryNotifierProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPreviewRoute(widget.previewPath);
    });
  }

  @override
  void didUpdateWidget(covariant GalleryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewPath != widget.previewPath) {
      _syncPreviewRoute(widget.previewPath);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGalleryKey);
    unawaited(_gamepadSubscription?.cancel());
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleGalleryKey(KeyEvent event) {
    if (_preview != null || event is! KeyDownEvent) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _moveGridSelection(-_gridColumnCount);
        return true;
      case LogicalKeyboardKey.arrowDown:
        _moveGridSelection(_gridColumnCount);
        return true;
      case LogicalKeyboardKey.arrowLeft:
        _moveGridSelection(-1);
        return true;
      case LogicalKeyboardKey.arrowRight:
        _moveGridSelection(1);
        return true;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _openSelectedGridItem();
        return true;
      case LogicalKeyboardKey.keyS:
        _toggleSidebar();
        return true;
      case LogicalKeyboardKey.keyF:
        unawaited(_toggleFullscreen());
        return true;
      case LogicalKeyboardKey.escape:
        if (_isFullscreen) {
          unawaited(_toggleFullscreen());
        } else {
          ref.read(galleryNotifierProvider.notifier).goUp();
        }
        return true;
      default:
        return false;
    }
  }

  void _handleGalleryGamepad(NormalizedGamepadEvent event) {
    if (_preview != null || event.button == null || event.value < 0.5) return;
    switch (event.button!) {
      case GamepadButton.dpadUp:
        _moveGridSelection(-_gridColumnCount);
        return;
      case GamepadButton.dpadDown:
        _moveGridSelection(_gridColumnCount);
        return;
      case GamepadButton.dpadLeft:
        _moveGridSelection(-1);
        return;
      case GamepadButton.dpadRight:
        _moveGridSelection(1);
        return;
      case GamepadButton.a:
        _openSelectedGridItem();
        return;
      case GamepadButton.b:
        ref.read(galleryNotifierProvider.notifier).goUp();
        return;
      case GamepadButton.back:
      case GamepadButton.touchpad:
        _toggleSidebar();
        return;
      case GamepadButton.y:
      case GamepadButton.start:
        unawaited(_toggleFullscreen());
        return;
      case GamepadButton.home:
      case GamepadButton.x:
      case GamepadButton.leftBumper:
      case GamepadButton.rightBumper:
      case GamepadButton.leftTrigger:
      case GamepadButton.rightTrigger:
      case GamepadButton.leftStick:
      case GamepadButton.rightStick:
        return;
    }
  }

  void _moveGridSelection(int delta) {
    final items = ref.read(galleryNotifierProvider).visibleItems;
    if (items.isEmpty) return;
    final next = (_selectedGridIndex + delta).clamp(0, items.length - 1);
    if (next != _selectedGridIndex) setState(() => _selectedGridIndex = next);
  }

  void _openSelectedGridItem() {
    final gallery = ref.read(galleryNotifierProvider);
    if (gallery.visibleItems.isEmpty) return;
    final index = _selectedGridIndex.clamp(0, gallery.visibleItems.length - 1);
    final item = gallery.visibleItems[index];
    if (item is GalleryFolder) {
      _selectedGridIndex = 0;
      ref.read(galleryNotifierProvider.notifier).openDirectory(item.path);
    } else if (item is MediaItem) {
      unawaited(_openMediaPreview(item));
    }
  }

  Future<void> _openMediaPreview(MediaItem item) async {
    context.goNamed(
      AppRoute.gallery.name,
      queryParameters: {'preview': item.path},
    );
  }

  Future<void> _syncPreviewRoute(String? mediaPath) async {
    final generation = ++_previewLoadGeneration;
    if (mediaPath == null) {
      if (_preview == null || !mounted) return;
      setState(() {
        _preview = null;
        if (_isFullscreen) {
          _sidebarVisible = _sidebarBeforeFullscreen ?? _sidebarVisible;
        }
        _sidebarBeforeFullscreen = null;
      });
      return;
    }
    if (_preview?.requestedMediaPath == mediaPath) return;
    await _loadMediaPreview(mediaPath, generation);
  }

  Future<void> _loadMediaPreview(String mediaPath, int generation) async {
    try {
      final entries = await ref.read(readGalleryDirectoryProvider)(
        path.dirname(mediaPath),
      );
      final media = entries.whereType<MediaItem>().toList()
        ..sort(
          (a, b) => _compareMedia(a, b, ref.read(galleryNotifierProvider).sort),
        );
      final initialIndex = media.indexWhere(
        (entry) => path.equals(entry.path, mediaPath),
      );
      if (!mounted ||
          generation != _previewLoadGeneration ||
          initialIndex < 0) {
        return;
      }
      setState(() {
        if (_preview == null && _isFullscreen) {
          _sidebarBeforeFullscreen = _sidebarVisible;
          _sidebarVisible = false;
        }
        _preview = _MediaPreviewSelection(
          items: media,
          initialIndex: initialIndex,
          folderPath: path.dirname(mediaPath),
          requestedMediaPath: mediaPath,
        );
      });
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open media folder: $error')),
      );
    }
  }

  int _compareMedia(MediaItem a, MediaItem b, GallerySort sort) {
    final comparison = switch (sort) {
      GallerySort.nameAscending => naturalCompare(a.name, b.name),
      GallerySort.nameDescending => naturalCompare(b.name, a.name),
      GallerySort.newest => b.modifiedAt.compareTo(a.modifiedAt),
      GallerySort.oldest => a.modifiedAt.compareTo(b.modifiedAt),
    };
    if (comparison != 0) return comparison;
    return naturalCompare(a.path, b.path);
  }

  void _toggleSidebar() {
    if (ref.read(settingsNotifierProvider).rootPath == null) return;
    setState(() => _sidebarVisible = !_sidebarVisible);
  }

  Future<void> _openFolder(String folderPath) async {
    if (_preview != null) {
      await _closePreview();
    }
    if (mounted) setState(() => _selectedGridIndex = 0);
    ref.read(galleryNotifierProvider.notifier).openDirectory(folderPath);
  }

  Future<void> _closePreview() async {
    if (mounted) context.goNamed(AppRoute.gallery.name);
  }

  Future<void> _toggleFullscreen() async {
    final target = !_isFullscreen;
    try {
      await windowManager.setFullScreen(target);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change fullscreen mode: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isFullscreen = target;
      if (target && _preview != null) {
        _sidebarBeforeFullscreen = _sidebarVisible;
        _sidebarVisible = false;
      } else if (!target && _preview != null) {
        _sidebarVisible = _sidebarBeforeFullscreen ?? _sidebarVisible;
        _sidebarBeforeFullscreen = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final gallery = ref.watch(galleryNotifierProvider);
    final previewState = _preview == null
        ? null
        : ref.watch(mediaPreviewNotifierProvider);
    final root = settings.rootPath;
    if (!settings.isLoading && root != null && root != _loadedRoot) {
      _loadedRoot = root;
      Future.microtask(
        () => ref.read(galleryNotifierProvider.notifier).setRoot(root),
      );
    }

    return Focus(
      autofocus: true,
      child: Scaffold(
        body: VirtualCursorOverlay(
          child: settings.isLoading
              ? const Center(child: CircularProgressIndicator())
              : root == null
              ? _ChooseFolder(
                  onPressed: () => ref
                      .read(settingsNotifierProvider.notifier)
                      .chooseRootFolder(),
                )
              : Row(
                  children: [
                    if (_sidebarVisible)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                        child: SizedBox(
                          width: 300,
                          child: ExcludeFocus(
                            child: FolderTreeSidebar(
                              rootPath: root,
                              currentFolderPath: gallery.currentPath ?? root,
                              activeMediaPath: previewState?.activeItem?.path,
                              sort: gallery.sort,
                              onClose: () =>
                                  setState(() => _sidebarVisible = false),
                              onFolderSelected: _openFolder,
                              onMediaSelected: _openMediaPreview,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (_preview == null || !_isFullscreen)
                            _ShellTopBar(
                              gallery: gallery,
                              isPreview: _preview != null,
                              previewTitle: previewState?.activeItem?.name,
                              sidebarVisible: _sidebarVisible,
                              onToggleSidebar: _toggleSidebar,
                              onClosePreview: _closePreview,
                              onToggleFullscreen: _toggleFullscreen,
                              onRootChanged: () => _loadedRoot = null,
                            ),
                          Expanded(
                            child: _preview != null
                                ? MediaPreviewPage(
                                    key: ValueKey(_preview!.requestedMediaPath),
                                    items: _preview!.items,
                                    initialIndex: _preview!.initialIndex,
                                    rootPath: root,
                                    currentFolderPath: _preview!.folderPath,
                                    sort: gallery.sort,
                                    embedded: true,
                                    sidebarVisible: _sidebarVisible,
                                    onToggleSidebar: _toggleSidebar,
                                    onClose: _closePreview,
                                    isFullscreen: _isFullscreen,
                                    onToggleFullscreen: _toggleFullscreen,
                                  )
                                : Column(
                                    children: [
                                      _PathBar(state: gallery),
                                      Expanded(
                                        child: _GalleryBody(
                                          state: gallery,
                                          scroll: _scrollController,
                                          selectedIndex: _selectedGridIndex,
                                          onSelectionChanged: (index) {
                                            setState(
                                              () => _selectedGridIndex = index,
                                            );
                                          },
                                          onColumnCountChanged: (count) {
                                            _gridColumnCount = count;
                                          },
                                          onFolderSelected: _openFolder,
                                          onMediaSelected: _openMediaPreview,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ShellTopBar extends ConsumerWidget {
  const _ShellTopBar({
    required this.gallery,
    required this.isPreview,
    required this.previewTitle,
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.onClosePreview,
    required this.onToggleFullscreen,
    required this.onRootChanged,
  });

  final GalleryUiState gallery;
  final bool isPreview;
  final String? previewTitle;
  final bool sidebarVisible;
  final VoidCallback onToggleSidebar;
  final VoidCallback onClosePreview;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onRootChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: isPreview ? 'Back to gallery' : 'Parent folder',
                    onPressed: isPreview
                        ? onClosePreview
                        : _canGoToParent(gallery)
                        ? ref.read(galleryNotifierProvider.notifier).goUp
                        : null,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft02,
                    ),
                  ),
                  IconButton(
                    tooltip: sidebarVisible ? 'Hide sidebar' : 'Show sidebar',
                    onPressed: onToggleSidebar,
                    icon: HugeIcon(
                      icon: sidebarVisible
                          ? HugeIcons.strokeRoundedSidebarLeft
                          : HugeIcons.strokeRoundedPanelLeftOpen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPreview
                          ? previewTitle ?? 'Media detail'
                          : 'Hello Gallery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (isPreview) ...[
                    IconButton(
                      tooltip: 'Fullscreen',
                      onPressed: onToggleFullscreen,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMaximizeScreen,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close detail',
                      onPressed: onClosePreview,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                      ),
                    ),
                  ] else ...[
                    if (gallery.status == GalleryStatus.ready ||
                        gallery.status == GalleryStatus.empty)
                      DropdownButtonHideUnderline(
                        child: DropdownButton<GallerySort>(
                          value: gallery.sort,
                          items: [
                            for (final sort in GallerySort.values)
                              DropdownMenuItem(
                                value: sort,
                                child: Text(sort.label),
                              ),
                          ],
                          onChanged: (sort) {
                            if (sort != null) {
                              ref
                                  .read(galleryNotifierProvider.notifier)
                                  .setSort(sort);
                            }
                          },
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Choose root folder',
                      onPressed: () async {
                        final changed = await ref
                            .read(settingsNotifierProvider.notifier)
                            .chooseRootFolder();
                        if (changed) onRootChanged();
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFolderAdd,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canGoToParent(GalleryUiState state) {
    final rootPath = state.rootPath;
    final currentPath = state.currentPath;
    return rootPath != null &&
        currentPath != null &&
        !path.equals(rootPath, currentPath);
  }
}

class _MediaPreviewSelection {
  const _MediaPreviewSelection({
    required this.items,
    required this.initialIndex,
    required this.folderPath,
    required this.requestedMediaPath,
  });

  final List<MediaItem> items;
  final int initialIndex;
  final String folderPath;
  final String requestedMediaPath;
}

class _PathBar extends ConsumerWidget {
  const _PathBar({required this.state});
  final GalleryUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: colorScheme.surfaceContainer,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.38),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    state.currentPath ?? state.rootPath ?? '',
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: state.currentPath == null
                      ? null
                      : () => ref
                            .read(galleryNotifierProvider.notifier)
                            .openDirectory(state.currentPath!),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryBody extends ConsumerStatefulWidget {
  const _GalleryBody({
    required this.state,
    required this.scroll,
    required this.selectedIndex,
    required this.onSelectionChanged,
    required this.onColumnCountChanged,
    required this.onFolderSelected,
    required this.onMediaSelected,
  });
  final GalleryUiState state;
  final ScrollController scroll;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;
  final ValueChanged<int> onColumnCountChanged;
  final ValueChanged<String> onFolderSelected;
  final ValueChanged<MediaItem> onMediaSelected;

  @override
  ConsumerState<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends ConsumerState<_GalleryBody> {
  final Map<String, GlobalKey> _itemKeys = {};
  late final ThumbnailJobScheduler _thumbnailScheduler;
  int _reportedColumnCount = 1;

  @override
  void initState() {
    super.initState();
    _thumbnailScheduler = ref.read(thumbnailJobSchedulerProvider);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _thumbnailScheduler.setScrolling(true);
    } else if (notification is ScrollEndNotification) {
      _thumbnailScheduler.setScrolling(false);
    }
    return false;
  }

  @override
  void dispose() {
    _thumbnailScheduler.setScrolling(false);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GalleryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
    }
  }

  void _revealSelection() {
    if (!mounted || widget.state.visibleItems.isEmpty) return;
    final index = widget.selectedIndex.clamp(
      0,
      widget.state.visibleItems.length - 1,
    );
    final key = _itemKeys[widget.state.visibleItems[index].path];
    final itemContext = key?.currentContext;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    switch (state.status) {
      case GalleryStatus.initial:
      case GalleryStatus.loading:
        return const _LoadingGrid();
      case GalleryStatus.empty:
        return const Center(child: Text('No supported media in this folder.'));
      case GalleryStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not read this folder.\n${state.errorMessage}'),
          ),
        );
      case GalleryStatus.ready:
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = ((constraints.maxWidth - 20) / 272).ceil().clamp(
              1,
              1000,
            );
            if (columns != _reportedColumnCount) {
              _reportedColumnCount = columns;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onColumnCountChanged(columns);
              });
            }
            return NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: GridView.builder(
                controller: widget.scroll,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 210,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: state.visibleItems.length,
                itemBuilder: (context, index) {
                  final item = state.visibleItems[index];
                  final itemKey = _itemKeys.putIfAbsent(
                    item.path,
                    GlobalKey.new,
                  );
                  return KeyedSubtree(
                    key: itemKey,
                    child: ExcludeFocus(
                      child: GalleryCard(
                        item: item,
                        selected: index == widget.selectedIndex,
                        onTap: () {
                          widget.onSelectionChanged(index);
                          if (item is GalleryFolder) {
                            widget.onFolderSelected(item.path);
                          } else if (item is MediaItem) {
                            widget.onMediaSelected(item);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
    }
  }
}

class _ChooseFolder extends StatelessWidget {
  const _ChooseFolder({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HugeIcon(icon: HugeIcons.strokeRoundedImageComposition, size: 72),
        const SizedBox(height: 20),
        Text(
          'Choose a folder to start',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onPressed,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedFolderOpen),
          label: const Text('Choose root folder'),
        ),
      ],
    ),
  );
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 260,
      mainAxisExtent: 210,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: 18,
    itemBuilder: (_, _) =>
        const Card(child: ColoredBox(color: Color(0xFF222229))),
  );
}
