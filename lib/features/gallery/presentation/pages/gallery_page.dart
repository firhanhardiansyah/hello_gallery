import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/rules/gallery_item_sort_rules.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/widgets/desktop_window_title_bar.dart';
import '../../../gamepad/presentation/widgets/virtual_cursor_overlay.dart';
import '../../../media_preview/presentation/notifiers/media_preview_notifier.dart';
import '../../../media_preview/presentation/pages/media_preview_page.dart';
import '../../../media_index/application/providers/media_index_dependencies.dart';
import '../../../media_index/domain/entities/file_change.dart';
import '../../../settings/presentation/notifiers/settings_notifier.dart';
import '../../application/providers/gallery_dependencies.dart';
import '../input/gallery_input_handler.dart';
import '../notifiers/gallery_notifier.dart';
import '../states/media_preview_selection.dart';
import '../widgets/folder_tree_sidebar.dart';
import '../widgets/folder_management/folder_management_dialogs.dart';
import '../widgets/gallery_page/choose_folder_prompt.dart';
import '../widgets/gallery_page/gallery_body.dart';
import '../widgets/gallery_page/group_media_dialog.dart';
import '../widgets/gallery_page/gallery_shell_top_bar.dart';

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
  bool _isModalOpen = false;
  MediaPreviewSelection? _preview;
  bool _isFullscreen = false;
  bool? _sidebarBeforeFullscreen;
  late final GalleryInputHandler _inputHandler;
  int _selectedGridIndex = 0;
  int _gridColumnCount = 1;
  int _previewLoadGeneration = 0;
  int _autoSyncGeneration = 0;
  int _folderTreeSyncRevision = 0;
  Set<String> _syncedDirectoryPaths = const {};

  @override
  void initState() {
    super.initState();
    _inputHandler = GalleryInputHandler(
      isEnabled: _isGalleryInputEnabled,
      onMoveUp: () => _moveGridSelection(-_gridColumnCount),
      onMoveDown: () => _moveGridSelection(_gridColumnCount),
      onMoveLeft: () => _moveGridSelection(-1),
      onMoveRight: () => _moveGridSelection(1),
      onActivate: _openSelectedGridItem,
      onBack: _handleBackInput,
      onToggleSidebar: _toggleSidebar,
      onToggleFullscreen: () => unawaited(_toggleFullscreen()),
    )..start();
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
    _inputHandler.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBackInput() {
    if (_isFullscreen) {
      unawaited(_toggleFullscreen());
    } else {
      final gallery = ref.read(galleryNotifierProvider);
      final notifier = ref.read(galleryNotifierProvider.notifier);
      if (gallery.canGoBack) {
        unawaited(notifier.goBack());
      } else {
        unawaited(notifier.goUp());
      }
    }
  }

  bool _isGalleryInputEnabled() {
    if (!mounted || _preview != null || _isModalOpen) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
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
          (a, b) => GalleryItemSortRules.compareMedia(
            a,
            b,
            ref.read(galleryNotifierProvider).sort,
          ),
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
        _preview = MediaPreviewSelection(
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

  Future<void> _handleAutoSync(FileChangeBatch batch) async {
    final generation = ++_autoSyncGeneration;
    final folderPreviewScheduler = ref.read(folderPreviewJobSchedulerProvider);
    final galleryState = ref.read(galleryNotifierProvider);
    final rootPath = galleryState.rootPath;
    if (rootPath != null) {
      for (final directoryPath in batch.affectedDirectoryPaths) {
        var ancestorPath = directoryPath;
        while (path.equals(rootPath, ancestorPath) ||
            path.isWithin(rootPath, ancestorPath)) {
          folderPreviewScheduler.invalidate(ancestorPath);
          if (path.equals(rootPath, ancestorPath)) break;
          final parentPath = path.dirname(ancestorPath);
          if (path.equals(parentPath, ancestorPath)) break;
          ancestorPath = parentPath;
        }
      }
    }
    for (final folder in galleryState.items.whereType<GalleryFolder>()) {
      final containsChangedPath = batch.changes.any(
        (change) =>
            path.equals(folder.path, change.path) ||
            path.isWithin(folder.path, change.path),
      );
      if (!containsChangedPath) continue;
      folderPreviewScheduler.invalidate(folder.path);
      ref.invalidate(folderPreviewProvider(folder));
    }
    await Future.wait([
      for (final change in batch.changes)
        if (change.type != FileChangeType.added)
          FileImage(File(change.path)).evict(),
    ]);

    if (!mounted) return;
    setState(() {
      _folderTreeSyncRevision++;
      _syncedDirectoryPaths = batch.affectedDirectoryPaths;
    });

    await ref
        .read(galleryNotifierProvider.notifier)
        .syncDirectories(
          batch.affectedDirectoryPaths,
          removedPaths: {
            for (final change in batch.changes)
              if (change.type == FileChangeType.removed) change.path,
          },
        );
    if (!mounted || generation != _autoSyncGeneration || _preview == null) {
      return;
    }

    final preview = _preview!;
    final previewFolderChanged = batch.affectedDirectoryPaths.any(
      (directoryPath) => path.equals(directoryPath, preview.folderPath),
    );
    if (!previewFolderChanged) return;

    try {
      final entries = await ref.read(readGalleryDirectoryProvider)(
        preview.folderPath,
      );
      final media = entries.whereType<MediaItem>().toList()
        ..sort(
          (a, b) => GalleryItemSortRules.compareMedia(
            a,
            b,
            ref.read(galleryNotifierProvider).sort,
          ),
        );
      if (!mounted || generation != _autoSyncGeneration) return;
      final hasMedia = await ref
          .read(mediaPreviewNotifierProvider.notifier)
          .reconcile(media);
      if (!mounted || generation != _autoSyncGeneration) return;
      if (!hasMedia) {
        await _closePreview();
        return;
      }

      final activeItem = ref.read(mediaPreviewNotifierProvider).activeItem!;
      final activeIndex = media.indexWhere(
        (item) => path.equals(item.path, activeItem.path),
      );
      setState(() {
        _preview = MediaPreviewSelection(
          items: media,
          initialIndex: activeIndex,
          folderPath: preview.folderPath,
          requestedMediaPath: activeItem.path,
        );
      });
      if (!path.equals(widget.previewPath ?? '', activeItem.path)) {
        context.goNamed(
          AppRoute.gallery.name,
          queryParameters: {'preview': activeItem.path},
        );
      }
    } on Object {
      // Keep the current preview while a file operation is still settling.
    }
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

  Future<void> _openGroupMedia() async {
    final gallery = ref.read(galleryNotifierProvider);
    final rootPath = gallery.rootPath;
    final currentPath = gallery.currentPath;
    if (rootPath == null || currentPath == null) return;
    await _whileModalOpen(() async {
      await showGroupMediaDialog(
        context: context,
        rootPath: rootPath,
        currentDirectoryPath: currentPath,
      );
    });
  }

  Future<T?> _whileModalOpen<T>(Future<T?> Function() action) async {
    if (_isModalOpen) return null;
    _isModalOpen = true;
    try {
      return await action();
    } finally {
      _isModalOpen = false;
    }
  }

  Future<void> _createFolder() async {
    final gallery = ref.read(galleryNotifierProvider);
    final rootPath = gallery.rootPath;
    final currentPath = gallery.currentPath;
    if (rootPath == null || currentPath == null) return;
    await _whileModalOpen(() async {
      final created = await showFolderNameDialog(
        context: context,
        title: 'Create folder',
        locationPath: currentPath,
        submitLabel: 'Create folder',
        onSubmit: (folderName) async {
          await ref.read(createFolderProvider)(
            rootPath: rootPath,
            parentPath: currentPath,
            folderName: folderName,
          );
        },
      );
      if (!created || !mounted) return;
      _notifyFolderTreeChanged({currentPath});
      await ref.read(galleryNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _renameFolder(String folderPath) async {
    final gallery = ref.read(galleryNotifierProvider);
    final rootPath = gallery.rootPath;
    if (rootPath == null || path.equals(rootPath, folderPath)) return;
    await _whileModalOpen(() async {
      String? newPath;
      final renamed = await showFolderNameDialog(
        context: context,
        title: 'Rename folder',
        locationPath: path.dirname(folderPath),
        initialName: path.basename(folderPath),
        submitLabel: 'Rename',
        onSubmit: (newName) async {
          newPath = await ref.read(renameFolderProvider)(
            rootPath: rootPath,
            folderPath: folderPath,
            newName: newName,
          );
        },
      );
      final destination = newPath;
      if (!renamed || destination == null || !mounted) return;
      if (path.equals(destination, folderPath)) return;
      if (_previewPathIsInside(folderPath)) await _closePreview();
      _notifyFolderTreeChanged({path.dirname(folderPath)});
      await ref
          .read(galleryNotifierProvider.notifier)
          .reconcileRenamedFolder(oldPath: folderPath, newPath: destination);
    });
  }

  Future<void> _deleteFolder(String folderPath) async {
    final gallery = ref.read(galleryNotifierProvider);
    final rootPath = gallery.rootPath;
    if (rootPath == null || path.equals(rootPath, folderPath)) return;
    await _whileModalOpen(() async {
      final confirmed = await showMoveFolderToTrashDialog(
        context: context,
        folderName: path.basename(folderPath),
      );
      if (!confirmed || !mounted) return;
      try {
        await runFolderOperationWithProgress<void>(
          context: context,
          message: 'Moving ${path.basename(folderPath)} to Trash...',
          operation: () => ref.read(moveFolderToTrashProvider)(
            rootPath: rootPath,
            folderPath: folderPath,
          ),
        );
      } on Object catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(folderOperationErrorMessage(error))),
        );
        return;
      }
      if (!mounted) return;
      if (_previewPathIsInside(folderPath)) await _closePreview();
      _notifyFolderTreeChanged({path.dirname(folderPath)});
      await ref
          .read(galleryNotifierProvider.notifier)
          .reconcileTrashedFolder(folderPath);
    });
  }

  bool _previewPathIsInside(String folderPath) {
    final previewPath = widget.previewPath;
    return previewPath != null &&
        (path.equals(folderPath, previewPath) ||
            path.isWithin(folderPath, previewPath));
  }

  void _notifyFolderTreeChanged(Set<String> paths) {
    if (!mounted) return;
    setState(() {
      _folderTreeSyncRevision++;
      _syncedDirectoryPaths = paths;
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
    if (root != null) {
      ref.listen(galleryAutoSyncProvider(root), (previous, next) {
        next.whenData((batch) => unawaited(_handleAutoSync(batch)));
      });
    }
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
              ? const _StandaloneWindowChrome(
                  child: Center(child: CircularProgressIndicator()),
                )
              : root == null
              ? _StandaloneWindowChrome(
                  child: ChooseFolderPrompt(
                    onPressed: () => ref
                        .read(settingsNotifierProvider.notifier)
                        .chooseRootFolder(),
                  ),
                )
              : Row(
                  children: [
                    if (_sidebarVisible)
                      SizedBox(
                        width: 300,
                        child: ExcludeFocus(
                          child: FolderTreeSidebar(
                            rootPath: root,
                            currentFolderPath: gallery.currentPath ?? root,
                            activeMediaPath: previewState?.activeItem?.path,
                            sort: gallery.sort,
                            onRefresh: gallery.currentPath == null
                                ? null
                                : ref
                                      .read(galleryNotifierProvider.notifier)
                                      .refresh,
                            onChooseRootFolder: () async {
                              final changed = await ref
                                  .read(settingsNotifierProvider.notifier)
                                  .chooseRootFolder();
                              if (changed) _loadedRoot = null;
                            },
                            onClose: () =>
                                setState(() => _sidebarVisible = false),
                            syncRevision: _folderTreeSyncRevision,
                            syncedDirectoryPaths: _syncedDirectoryPaths,
                            onFolderSelected: _openFolder,
                            onRenameFolder: _preview == null
                                ? _renameFolder
                                : null,
                            onDeleteFolder: _preview == null
                                ? _deleteFolder
                                : null,
                            onMediaSelected: _openMediaPreview,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (_preview == null || !_isFullscreen)
                            GalleryShellTopBar(
                              gallery: gallery,
                              isPreview: _preview != null,
                              previewTitle: previewState?.activeItem?.name,
                              sidebarVisible: _sidebarVisible,
                              onToggleSidebar: _toggleSidebar,
                              onClosePreview: _closePreview,
                              onCreateFolder: _createFolder,
                              onGroupMedia: _openGroupMedia,
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
                                : GalleryBody(
                                    state: gallery,
                                    scrollController: _scrollController,
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
                                    onRenameFolder: _renameFolder,
                                    onDeleteFolder: _deleteFolder,
                                    onMediaSelected: _openMediaPreview,
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

class _StandaloneWindowChrome extends StatelessWidget {
  const _StandaloneWindowChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      DesktopWindowTitleBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        reserveMacOSWindowButtons: true,
        child: const SizedBox.shrink(),
      ),
      Expanded(child: child),
    ],
  );
}
