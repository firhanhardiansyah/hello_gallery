import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

import '../../shared/models/gallery_item.dart';
import '../../shared/models/gallery_sort.dart';
import '../../shared/utils/natural_compare.dart';
import '../gamepad/virtual_cursor_overlay.dart';
import '../media_detail/media_detail_controller.dart';
import '../media_detail/media_detail_page.dart';
import '../settings/settings_controller.dart';
import 'gallery_controller.dart';
import 'gallery_service.dart';
import 'gallery_state.dart';
import 'widgets/folder_tree_sidebar.dart';
import 'widgets/gallery_card.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  final _scrollController = ScrollController();
  String? _loadedRoot;
  bool _sidebarVisible = true;
  _DetailSelection? _detail;
  bool _isFullscreen = false;
  bool? _sidebarBeforeFullscreen;
  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;
  int _selectedGridIndex = 0;
  int _gridColumnCount = 1;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGalleryKey);
    _gamepadSubscription = Gamepads.normalizedEvents.listen(
      _handleGalleryGamepad,
    );
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 600) {
        ref.read(galleryControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGalleryKey);
    unawaited(_gamepadSubscription?.cancel());
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleGalleryKey(KeyEvent event) {
    if (_detail != null || event is! KeyDownEvent) return false;
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
          ref.read(galleryControllerProvider.notifier).goUp();
        }
        return true;
      default:
        return false;
    }
  }

  void _handleGalleryGamepad(NormalizedGamepadEvent event) {
    if (_detail != null || event.button == null || event.value < 0.5) return;
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
        ref.read(galleryControllerProvider.notifier).goUp();
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
    final items = ref.read(galleryControllerProvider).visibleItems;
    if (items.isEmpty) return;
    final next = (_selectedGridIndex + delta).clamp(0, items.length - 1);
    if (next != _selectedGridIndex) setState(() => _selectedGridIndex = next);
  }

  void _openSelectedGridItem() {
    final gallery = ref.read(galleryControllerProvider);
    if (gallery.visibleItems.isEmpty) return;
    final index = _selectedGridIndex.clamp(0, gallery.visibleItems.length - 1);
    final item = gallery.visibleItems[index];
    if (item is GalleryFolder) {
      _selectedGridIndex = 0;
      ref.read(galleryControllerProvider.notifier).openDirectory(item.path);
    } else if (item is MediaItem) {
      unawaited(_openMediaDetail(item, gallery));
    }
  }

  Future<void> _openMediaDetail(MediaItem item, GalleryState gallery) async {
    try {
      final entries = await ref
          .read(galleryServiceProvider)
          .scan(path.dirname(item.path));
      final media = entries.whereType<MediaItem>().toList()
        ..sort((a, b) => _compareMedia(a, b, gallery.sort));
      final initialIndex = media.indexWhere(
        (entry) => path.equals(entry.path, item.path),
      );
      if (!mounted || initialIndex < 0) return;
      setState(() {
        if (_detail == null && _isFullscreen) {
          _sidebarBeforeFullscreen = _sidebarVisible;
          _sidebarVisible = false;
        }
        _detail = _DetailSelection(
          items: media,
          initialIndex: initialIndex,
          folderPath: path.dirname(item.path),
          requestedMediaPath: item.path,
        );
      });
    } on FileSystemException catch (error) {
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
    if (ref.read(settingsControllerProvider).rootPath == null) return;
    setState(() => _sidebarVisible = !_sidebarVisible);
  }

  Future<void> _openFolder(String folderPath) async {
    if (_detail != null) {
      await _closeDetail();
    }
    if (mounted) setState(() => _selectedGridIndex = 0);
    ref.read(galleryControllerProvider.notifier).openDirectory(folderPath);
  }

  Future<void> _closeDetail() async {
    if (!mounted) return;
    setState(() {
      _detail = null;
      if (_isFullscreen) {
        _sidebarVisible = _sidebarBeforeFullscreen ?? _sidebarVisible;
      }
      _sidebarBeforeFullscreen = null;
    });
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
      if (target && _detail != null) {
        _sidebarBeforeFullscreen = _sidebarVisible;
        _sidebarVisible = false;
      } else if (!target && _detail != null) {
        _sidebarVisible = _sidebarBeforeFullscreen ?? _sidebarVisible;
        _sidebarBeforeFullscreen = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final gallery = ref.watch(galleryControllerProvider);
    final detailState = _detail == null
        ? null
        : ref.watch(mediaDetailControllerProvider);
    final root = settings.rootPath;
    if (!settings.isLoading && root != null && root != _loadedRoot) {
      _loadedRoot = root;
      Future.microtask(
        () => ref.read(galleryControllerProvider.notifier).setRoot(root),
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
                      .read(settingsControllerProvider.notifier)
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
                              activeMediaPath: detailState?.activeItem?.path,
                              sort: gallery.sort,
                              onClose: () =>
                                  setState(() => _sidebarVisible = false),
                              onFolderSelected: _openFolder,
                              onMediaSelected: (item) =>
                                  _openMediaDetail(item, gallery),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (_detail == null || !_isFullscreen)
                            _ShellTopBar(
                              gallery: gallery,
                              isDetail: _detail != null,
                              detailTitle: detailState?.activeItem?.name,
                              sidebarVisible: _sidebarVisible,
                              onToggleSidebar: _toggleSidebar,
                              onCloseDetail: _closeDetail,
                              onToggleFullscreen: _toggleFullscreen,
                              onRootChanged: () => _loadedRoot = null,
                            ),
                          Expanded(
                            child: _detail != null
                                ? MediaDetailPage(
                                    key: ValueKey(_detail!.requestedMediaPath),
                                    items: _detail!.items,
                                    initialIndex: _detail!.initialIndex,
                                    rootPath: root,
                                    currentFolderPath: _detail!.folderPath,
                                    sort: gallery.sort,
                                    embedded: true,
                                    sidebarVisible: _sidebarVisible,
                                    onToggleSidebar: _toggleSidebar,
                                    onClose: _closeDetail,
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
                                          onMediaSelected: (item) =>
                                              _openMediaDetail(item, gallery),
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
    required this.isDetail,
    required this.detailTitle,
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.onCloseDetail,
    required this.onToggleFullscreen,
    required this.onRootChanged,
  });

  final GalleryState gallery;
  final bool isDetail;
  final String? detailTitle;
  final bool sidebarVisible;
  final VoidCallback onToggleSidebar;
  final VoidCallback onCloseDetail;
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
                    tooltip: isDetail ? 'Back to gallery' : 'Parent folder',
                    onPressed: isDetail
                        ? onCloseDetail
                        : _canGoToParent(gallery)
                        ? ref.read(galleryControllerProvider.notifier).goUp
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  IconButton(
                    tooltip: sidebarVisible ? 'Hide sidebar' : 'Show sidebar',
                    onPressed: onToggleSidebar,
                    icon: Icon(
                      sidebarVisible
                          ? Icons.view_sidebar_outlined
                          : Icons.menu_open_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDetail
                          ? detailTitle ?? 'Media detail'
                          : 'Local Gallery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (isDetail) ...[
                    IconButton(
                      tooltip: 'Fullscreen',
                      onPressed: onToggleFullscreen,
                      icon: const Icon(Icons.fullscreen_rounded),
                    ),
                    IconButton(
                      tooltip: 'Close detail',
                      onPressed: onCloseDetail,
                      icon: const Icon(Icons.close_rounded),
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
                                  .read(galleryControllerProvider.notifier)
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
                            .read(settingsControllerProvider.notifier)
                            .chooseRootFolder();
                        if (changed) onRootChanged();
                      },
                      icon: const Icon(Icons.create_new_folder_outlined),
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

  bool _canGoToParent(GalleryState state) {
    final rootPath = state.rootPath;
    final currentPath = state.currentPath;
    return rootPath != null &&
        currentPath != null &&
        !path.equals(rootPath, currentPath);
  }
}

class _DetailSelection {
  const _DetailSelection({
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
  final GalleryState state;

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
                            .read(galleryControllerProvider.notifier)
                            .openDirectory(state.currentPath!),
                  icon: const Icon(Icons.refresh_rounded),
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
  final GalleryState state;
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
  int _reportedColumnCount = 1;

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
            return GridView.builder(
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
                final itemKey = _itemKeys.putIfAbsent(item.path, GlobalKey.new);
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
        const Icon(Icons.photo_library_outlined, size: 72),
        const SizedBox(height: 20),
        Text(
          'Choose a folder to start',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.folder_open),
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
