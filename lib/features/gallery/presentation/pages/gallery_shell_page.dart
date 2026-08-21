import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_gallery/app/routing/app_router.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/core/widgets/desktop_window_title_bar.dart';
import 'package:hello_gallery/features/gallery/application/providers/gallery_dependencies.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hello_gallery/features/gallery/presentation/gallery_presentation.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/folder_tree/folder_tree_sidebar.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_page_widgets.dart';
import 'package:hello_gallery/features/gamepad/presentation/widgets/virtual_cursor_overlay.dart';
import 'package:hello_gallery/features/media_index/application/providers/media_index_dependencies.dart';
import 'package:hello_gallery/features/media_preview/presentation/media_preview_presentation.dart';
import 'package:hello_gallery/features/settings/presentation/settings_presentation.dart';
import 'package:hello_gallery/features/thumbnail/application/providers/thumbnail_dependencies.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

import 'gallery_shell_scope.dart';

class GalleryShellPage extends ConsumerStatefulWidget {
  const GalleryShellPage({
    required this.child,
    required this.isPreviewRoute,
    this.previewPath,
    super.key,
  });

  final Widget child;
  final bool isPreviewRoute;
  final String? previewPath;

  @override
  ConsumerState<GalleryShellPage> createState() => _GalleryShellPageState();
}

class _GalleryShellPageState extends ConsumerState<GalleryShellPage> {
  final _scrollController = ScrollController();
  String? _loadedRoot;
  bool _sidebarVisible = true;
  double _sidebarWidth = AnimatedGallerySidebar.defaultWidth;
  bool _isModalOpen = false;
  MediaPreviewSelection? _preview;
  bool _isFullscreen = false;
  bool _previewTopBarVisible = true;
  bool? _sidebarBeforeFullscreen;
  bool _cleanPreviewEnabled = false;
  bool? _sidebarBeforeCleanPreview;
  bool? _topBarBeforeCleanPreview;
  late final GalleryInputHandler _inputHandler;
  late final GalleryPageInputActions _inputActions;
  late final GalleryFolderActions _folderActions;
  late final GalleryMediaActions _mediaActions;
  late final GalleryPreviewCoordinator _previewCoordinator;
  late final GalleryScrollRestorer _scrollRestorer;
  late final GalleryAutoSyncCoordinator _autoSyncCoordinator;
  GallerySelectionState _selection = const GallerySelectionState();
  int _gridColumnCount = 1;
  int _folderTreeSyncRevision = 0;
  Set<String> _syncedDirectoryPaths = const {};

  bool get _isPreviewRoute => widget.isPreviewRoute;

  @override
  void initState() {
    super.initState();
    _initializeActions();
    _scrollRestorer = GalleryScrollRestorer(
      scrollController: _scrollController,
      isMounted: () => mounted,
      isPreviewActive: () => _isPreviewRoute,
    );
    _inputHandler = GalleryInputHandler(
      isEnabled: _isGalleryInputEnabled,
      isNavigationEnabled: _isHistoryNavigationEnabled,
      onMoveUp: () => _inputActions.moveSelection(-_gridColumnCount),
      onMoveDown: () => _inputActions.moveSelection(_gridColumnCount),
      onMoveLeft: () => _inputActions.moveSelection(-1),
      onMoveRight: () => _inputActions.moveSelection(1),
      onActivate: _inputActions.openSelectedItem,
      onBack: _inputActions.handleBack,
      onGamepadBack: _inputActions.handleGamepadBack,
      onToggleSelectAll: _inputActions.toggleSelectAll,
      onIncreaseItemSize: () => unawaited(
        ref.read(settingsNotifierProvider.notifier).increaseGalleryItemExtent(),
      ),
      onDecreaseItemSize: () => unawaited(
        ref.read(settingsNotifierProvider.notifier).decreaseGalleryItemExtent(),
      ),
      onToggleSidebar: _toggleSidebar,
      onToggleFullscreen: () => unawaited(_toggleFullscreen()),
      onNavigateBack: _handleHistoryNavigationBack,
      onNavigateForward: _handleHistoryNavigationForward,
    )..start();
    _scrollController.addListener(_loadMoreNearGridEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previewCoordinator.syncRoute(widget.previewPath);
    });
  }

  @override
  void didUpdateWidget(covariant GalleryShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPreviewRoute && !widget.isPreviewRoute) {
      _restoreCleanPreviewState();
    }
    if (oldWidget.previewPath != widget.previewPath) {
      _previewCoordinator.syncRoute(widget.previewPath);
    }
  }

  @override
  void dispose() {
    _inputHandler.dispose();
    _scrollRestorer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeActions() {
    _previewCoordinator = GalleryPreviewCoordinator(
      readDirectory: (directoryPath) =>
          ref.read(readGalleryDirectoryProvider)(directoryPath),
      readSort: () => ref.read(galleryNotifierProvider).sort,
      readPreview: () => _preview,
      updatePreview: _setPreview,
      isMounted: () => mounted,
      openPreviewRoute: _openPreviewRoute,
      closePreviewRoute: _closePreviewRoute,
      showOpenError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open media folder: $error')),
        );
      },
    );
    _inputActions = GalleryPageInputActions(
      readGallery: () => ref.read(galleryNotifierProvider),
      readSelection: () => _selection,
      updateSelection: _setSelection,
      isPreviewActive: () => _preview != null,
      openFolder: _openFolder,
      openMedia: _previewCoordinator.open,
      goBack: ref.read(galleryNotifierProvider.notifier).goBack,
      goForward: ref.read(galleryNotifierProvider.notifier).goForward,
      goUp: ref.read(galleryNotifierProvider.notifier).goUp,
    );
    _folderActions = GalleryFolderActions(
      runModal: _whileModalOpen,
      createFolder:
          ({required rootPath, required parentPath, required folderName}) =>
              ref.read(createFolderProvider)(
                rootPath: rootPath,
                parentPath: parentPath,
                folderName: folderName,
              ),
      renameFolder:
          ({required rootPath, required folderPath, required newName}) =>
              ref.read(renameFolderProvider)(
                rootPath: rootPath,
                folderPath: folderPath,
                newName: newName,
              ),
      trashFolder: ({required rootPath, required folderPath}) => ref.read(
        moveFolderToTrashProvider,
      )(rootPath: rootPath, folderPath: folderPath),
      refreshGallery: ref.read(galleryNotifierProvider.notifier).refresh,
      reconcileRenamedFolder: ref
          .read(galleryNotifierProvider.notifier)
          .reconcileRenamedFolder,
      reconcileTrashedFolder: ref
          .read(galleryNotifierProvider.notifier)
          .reconcileTrashedFolder,
      isPreviewPathInside: _previewPathIsInside,
      closePreview: _previewCoordinator.close,
      notifyFolderTreeChanged: _notifyFolderTreeChanged,
    );
    final mediaCacheInvalidator = GalleryMediaCacheInvalidator(
      thumbnailScheduler: ref.read(thumbnailJobSchedulerProvider),
      invalidateThumbnailProviders: (item) {
        ref.invalidate(videoThumbnailProvider(item));
        ref.invalidate(cachedVideoThumbnailProvider(item));
      },
    );
    _mediaActions = GalleryMediaActions(
      runModal: _whileModalOpen,
      moveMedia: ({required items, required destinationPath}) => ref.read(
        moveMediaItemsProvider,
      )(items: items, destinationPath: destinationPath, onProgress: (_) {}),
      renameMedia:
          ({required rootPath, required mediaPath, required newBaseName}) =>
              ref.read(renameMediaProvider)(
                rootPath: rootPath,
                mediaPath: mediaPath,
                newBaseName: newBaseName,
              ),
      trashMedia: ({required rootPath, required items}) =>
          ref.read(moveMediaToTrashProvider)(rootPath: rootPath, items: items),
      syncDirectories: (directoryPaths) => ref
          .read(galleryNotifierProvider.notifier)
          .syncDirectories(directoryPaths),
      clearFolderPreviewCache: ref
          .read(folderPreviewJobSchedulerProvider)
          .clear,
      invalidateMediaCache: mediaCacheInvalidator.call,
      notifyFolderTreeChanged: _notifyFolderTreeChanged,
      removeSelectedPaths: (paths) =>
          _setSelection(_selection.removePaths(paths)),
      clearSelection: _inputActions.clearSelection,
    );
    _autoSyncCoordinator = GalleryAutoSyncCoordinator(
      folderPreviewScheduler: ref.read(folderPreviewJobSchedulerProvider),
      readGallery: () => ref.read(galleryNotifierProvider),
      readSort: () => ref.read(galleryNotifierProvider).sort,
      readDirectory: (directoryPath) =>
          ref.read(readGalleryDirectoryProvider)(directoryPath),
      readPreview: () => _preview,
      updatePreview: _setPreview,
      reconcileMediaPreview: (items) =>
          ref.read(mediaPreviewNotifierProvider.notifier).reconcile(items),
      readActiveMedia: () => ref.read(mediaPreviewNotifierProvider).activeItem,
      syncDirectories: (directoryPaths, {removedPaths = const {}}) => ref
          .read(galleryNotifierProvider.notifier)
          .syncDirectories(directoryPaths, removedPaths: removedPaths),
      invalidateFolderPreview: (folder) {
        ref.invalidate(folderPreviewProvider(folder));
      },
      notifyFolderTreeChanged: _notifyFolderTreeChanged,
      closePreview: _previewCoordinator.close,
      openPreviewRoute: _openPreviewRoute,
      readRoutePreviewPath: () => widget.previewPath,
      isMounted: () => mounted,
    );
  }

  void _setSelection(GallerySelectionState selection) {
    if (!mounted || identical(selection, _selection)) return;
    setState(() => _selection = selection);
  }

  void _setPreview(MediaPreviewSelection? preview) {
    if (!mounted) return;
    final isClosingPreview = preview == null && _preview != null;
    setState(() {
      if (preview == null) {
        _preview = null;
        _previewTopBarVisible = true;
        if (_isFullscreen) {
          _sidebarVisible = _sidebarBeforeFullscreen ?? _sidebarVisible;
        }
        _sidebarBeforeFullscreen = null;
        return;
      }
      if (_preview == null && _isFullscreen) {
        _sidebarBeforeFullscreen = _sidebarVisible;
        _sidebarVisible = false;
      }
      if (_preview == null) _previewTopBarVisible = true;
      _preview = preview;
    });
    if (isClosingPreview) _scrollRestorer.restoreAfterPreview();
  }

  void _openPreviewRoute(String mediaPath) {
    if (!mounted) return;
    if (_preview == null) _scrollRestorer.captureBeforePreview();
    context.goNamed(
      AppRoute.mediaPreview.name,
      queryParameters: {'path': mediaPath},
    );
  }

  void _closePreviewRoute() {
    if (mounted) context.goNamed(AppRoute.gallery.name);
  }

  void _loadMoreNearGridEnd() {
    if (_scrollController.position.extentAfter < 600) {
      ref.read(galleryNotifierProvider.notifier).loadMore();
    }
  }

  bool _isGalleryInputEnabled() {
    if (!mounted || _isPreviewRoute || _isModalOpen) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
  }

  bool _isHistoryNavigationEnabled() {
    if (!mounted || _isModalOpen) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
  }

  void _handleHistoryNavigationBack() {
    if (_isPreviewRoute) {
      unawaited(_previewCoordinator.close());
      return;
    }
    _inputActions.navigateHistoryBack();
  }

  void _handleHistoryNavigationForward() {
    if (!ref.read(galleryNotifierProvider).canGoForward) return;
    if (!_isPreviewRoute) {
      _inputActions.navigateForward();
      return;
    }
    unawaited(_closePreviewAndNavigateForward());
  }

  Future<void> _closePreviewAndNavigateForward() async {
    await _previewCoordinator.close();
    if (mounted) _inputActions.navigateForward();
  }

  void _toggleSidebar() {
    if (ref.read(settingsNotifierProvider).rootPath == null) return;
    setState(() {
      _sidebarVisible = !_sidebarVisible;
      if (_sidebarVisible &&
          _sidebarWidth <= AnimatedGallerySidebar.minimumWidth) {
        _sidebarWidth = AnimatedGallerySidebar.defaultWidth;
      }
    });
  }

  Future<void> _openFolder(String folderPath) async {
    if (_isPreviewRoute) await _previewCoordinator.close();
    if (mounted) {
      _setSelection(_selection.resetForFolder(folderPath));
    }
    ref.read(galleryNotifierProvider.notifier).openDirectory(folderPath);
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
      if (target && _isPreviewRoute) {
        _sidebarBeforeFullscreen = _sidebarVisible;
        _sidebarVisible = false;
      } else if (!target && _isPreviewRoute) {
        _sidebarVisible = _cleanPreviewEnabled
            ? false
            : _sidebarBeforeFullscreen ?? _sidebarVisible;
        _sidebarBeforeFullscreen = null;
      }
    });
  }

  void _togglePreviewTopBar() {
    if (!_isPreviewRoute || _cleanPreviewEnabled) return;
    setState(() {
      _previewTopBarVisible = !_previewTopBarVisible;
    });
  }

  void _syncPreviewTopBarVisibility(bool visible) {
    if (!mounted ||
        !_isPreviewRoute ||
        _cleanPreviewEnabled ||
        _previewTopBarVisible == visible) {
      return;
    }
    setState(() => _previewTopBarVisible = visible);
  }

  void _setCleanPreviewEnabled(bool enabled) {
    if (_cleanPreviewEnabled == enabled) return;
    setState(() {
      if (enabled) {
        _cleanPreviewEnabled = true;
        _sidebarBeforeCleanPreview = _isFullscreen
            ? _sidebarBeforeFullscreen ?? _sidebarVisible
            : _sidebarVisible;
        _topBarBeforeCleanPreview = _previewTopBarVisible;
        _sidebarVisible = false;
        _previewTopBarVisible = false;
        return;
      }
      _restoreCleanPreviewState();
    });
  }

  void _restoreCleanPreviewState() {
    if (!_cleanPreviewEnabled) return;
    final sidebarVisible = _sidebarBeforeCleanPreview ?? _sidebarVisible;
    _cleanPreviewEnabled = false;
    _previewTopBarVisible = _topBarBeforeCleanPreview ?? _previewTopBarVisible;
    if (_isFullscreen) {
      _sidebarVisible = false;
      _sidebarBeforeFullscreen = sidebarVisible;
    } else {
      _sidebarVisible = sidebarVisible;
    }
    _sidebarBeforeCleanPreview = null;
    _topBarBeforeCleanPreview = null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final gallery = ref.watch(galleryNotifierProvider);
    final selectedMediaItems = [
      for (final item in gallery.visibleItems.whereType<MediaItem>())
        if (_selection.selectedPaths.contains(item.path)) item,
    ];
    _reconcileSelectionFolder(gallery.currentPath);

    MediaPreviewUiState? previewState;
    if (_preview != null) {
      previewState = ref.watch(mediaPreviewNotifierProvider);
    }
    _listenToRoot(settings.rootPath, settings.gallerySort);

    return Focus(
      autofocus: true,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _inputHandler.handlePointerDown,
        child: Scaffold(
          body: VirtualCursorOverlay(
            showCursor: !_cleanPreviewEnabled,
            child: _buildPageContent(
              settings: settings,
              gallery: gallery,
              previewState: previewState,
              selectedMediaItems: selectedMediaItems,
            ),
          ),
        ),
      ),
    );
  }

  void _reconcileSelectionFolder(String? folderPath) {
    if (_selection.folderPath != null &&
        folderPath != null &&
        path.equals(_selection.folderPath!, folderPath)) {
      return;
    }
    _selection = _selection.resetForFolder(folderPath);
  }

  void _listenToRoot(String? rootPath, GallerySort sort) {
    if (rootPath == null) return;
    ref.listen(galleryAutoSyncProvider(rootPath), (previous, next) {
      next.whenData((batch) => unawaited(_autoSyncCoordinator.handle(batch)));
    });
    if (rootPath == _loadedRoot) return;
    _loadedRoot = rootPath;
    Future.microtask(
      () => ref
          .read(galleryNotifierProvider.notifier)
          .setRoot(rootPath, sort: sort),
    );
  }

  Widget _buildPageContent({
    required SettingsUiState settings,
    required GalleryUiState gallery,
    required MediaPreviewUiState? previewState,
    required List<MediaItem> selectedMediaItems,
  }) {
    return settings.loadState.when<Widget>(
      loading: () => const _StandaloneWindowChrome(
        child: Center(child: CircularProgressIndicator()),
      ),
      rootRequired: () => _StandaloneWindowChrome(
        child: ChooseFolderPrompt(
          onPressed: () =>
              ref.read(settingsNotifierProvider.notifier).chooseRootFolder(),
        ),
      ),
      ready: (rootPath) => _buildGalleryWorkspace(
        rootPath: rootPath,
        settings: settings,
        gallery: gallery,
        previewState: previewState,
        selectedMediaItems: selectedMediaItems,
      ),
      error: (message) => _StandaloneWindowChrome(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: ref.read(settingsNotifierProvider.notifier).reload,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryWorkspace({
    required String rootPath,
    required SettingsUiState settings,
    required GalleryUiState gallery,
    required MediaPreviewUiState? previewState,
    required List<MediaItem> selectedMediaItems,
  }) {
    final routeContent = GalleryShellScope(
      galleryPage: GalleryPageBindings(
        gallery: gallery,
        settings: settings,
        selection: _selection,
        scrollController: _scrollController,
        onSelectionChanged: _inputActions.changeSelection,
        onClearSelection: _inputActions.clearSelection,
        onColumnCountChanged: (count) => _gridColumnCount = count,
        onFolderSelected: _openFolder,
        onRenameFolder: (folderPath) => _folderActions.rename(
          context: context,
          rootPath: rootPath,
          folderPath: folderPath,
        ),
        onDeleteFolder: (folderPath) => _folderActions.delete(
          context: context,
          rootPath: rootPath,
          folderPath: folderPath,
        ),
        onRenameMedia: (item) => _mediaActions.rename(
          context: context,
          rootPath: rootPath,
          item: item,
        ),
        onDeleteMedia: (items) => _mediaActions.delete(
          context: context,
          rootPath: rootPath,
          items: items,
        ),
        onMediaDropped: (payload, destinationPath) =>
            _mediaActions.moveToFolder(
              context: context,
              payload: payload,
              destinationPath: destinationPath,
            ),
        onMediaSelected: _previewCoordinator.open,
      ),
      mediaPreviewPage: MediaPreviewPageBindings(
        selection: _preview,
        rootPath: rootPath,
        gallery: gallery,
        sidebarVisible: _sidebarVisible,
        isFullscreen: _isFullscreen,
        onToggleSidebar: _toggleSidebar,
        onToggleTopBar: _togglePreviewTopBar,
        onControlsVisibilityChanged: _syncPreviewTopBarVisibility,
        onCleanPreviewChanged: _setCleanPreviewEnabled,
        onClose: _previewCoordinator.close,
        onToggleFullscreen: _toggleFullscreen,
      ),
      child: widget.child,
    );
    return Row(
      children: [
        _buildSidebar(
          rootPath: rootPath,
          gallery: gallery,
          previewState: previewState,
        ),
        Expanded(
          child: _buildMainPanel(
            rootPath: rootPath,
            settings: settings,
            gallery: gallery,
            previewState: previewState,
            selectedMediaItems: selectedMediaItems,
            routeContent: routeContent,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar({
    required String rootPath,
    required GalleryUiState gallery,
    required MediaPreviewUiState? previewState,
  }) {
    VoidCallback? onRefresh;
    ValueChanged<String>? onRenameFolder;
    ValueChanged<String>? onDeleteFolder;
    MediaFolderDrop? onMediaDropped;
    if (gallery.currentPath != null) {
      onRefresh = ref.read(galleryNotifierProvider.notifier).refresh;
    }
    if (!_isPreviewRoute) {
      onRenameFolder = (folderPath) {
        final rootPath = gallery.rootPath;
        if (rootPath == null) return;
        _folderActions.rename(
          context: context,
          rootPath: rootPath,
          folderPath: folderPath,
        );
      };
      onDeleteFolder = (folderPath) {
        final rootPath = gallery.rootPath;
        if (rootPath == null) return;
        _folderActions.delete(
          context: context,
          rootPath: rootPath,
          folderPath: folderPath,
        );
      };
      onMediaDropped = (payload, destinationPath) => _mediaActions.moveToFolder(
        context: context,
        payload: payload,
        destinationPath: destinationPath,
      );
    }

    return AnimatedGallerySidebar(
      visible: _sidebarVisible,
      width: _sidebarWidth,
      onWidthChanged: (width) {
        if (width == _sidebarWidth) return;
        setState(() => _sidebarWidth = width);
      },
      onMinWidthReached: () {
        if (_sidebarVisible) setState(() => _sidebarVisible = false);
      },
      child: ExcludeFocus(
        excluding: !_sidebarVisible,
        child: FolderTreeSidebar(
          rootPath: rootPath,
          currentFolderPath: gallery.currentPath ?? rootPath,
          activeMediaPath: previewState?.activeItem?.path,
          sort: gallery.sort,
          onRefresh: onRefresh,
          onChooseRootFolder: _chooseRootFolder,
          onClose: () => setState(() => _sidebarVisible = false),
          syncRevision: _folderTreeSyncRevision,
          syncedDirectoryPaths: _syncedDirectoryPaths,
          onFolderSelected: _openFolder,
          onRenameFolder: onRenameFolder,
          onDeleteFolder: onDeleteFolder,
          onMediaDropped: onMediaDropped,
          onMediaSelected: _previewCoordinator.open,
        ),
      ),
    );
  }

  Future<void> _chooseRootFolder() async {
    final changed = await ref
        .read(settingsNotifierProvider.notifier)
        .chooseRootFolder();
    if (changed) _loadedRoot = null;
  }

  Widget _buildMainPanel({
    required String rootPath,
    required SettingsUiState settings,
    required GalleryUiState gallery,
    required MediaPreviewUiState? previewState,
    required List<MediaItem> selectedMediaItems,
    required Widget routeContent,
  }) {
    final topBar = GalleryShellTopBar(
      gallery: gallery,
      isPreview: _isPreviewRoute,
      isFullscreen: _isFullscreen,
      previewTitle: previewState?.activeItem?.name,
      sidebarVisible: _sidebarVisible,
      onToggleSidebar: _toggleSidebar,
      onClosePreview: _previewCoordinator.close,
      onCreateFolder: () {
        final currentPath = gallery.currentPath;
        if (currentPath == null) return;
        _folderActions.create(
          context: context,
          rootPath: rootPath,
          currentPath: currentPath,
        );
      },
      onGroupMedia: () {
        final currentPath = gallery.currentPath;
        if (currentPath == null) return;
        _mediaActions.openGroupDialog(
          context: context,
          rootPath: rootPath,
          currentPath: currentPath,
        );
      },
      selectedItemCount: _selection.selectedPaths.length,
      totalItemCount: gallery.visibleItems.length,
      onSelectAll: _inputActions.selectAll,
      onClearSelection: _inputActions.clearSelection,
      selectedMediaCount: selectedMediaItems.length,
      onDeleteSelectedMedia: () => _mediaActions.delete(
        context: context,
        rootPath: rootPath,
        items: selectedMediaItems,
      ),
    );
    if (!_isPreviewRoute) {
      return Column(
        children: [
          topBar,
          Expanded(child: routeContent),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        routeContent,
        PreviewShellTopBarOverlay(
          visible: _previewTopBarVisible,
          forceHidden: _cleanPreviewEnabled,
          child: topBar,
        ),
      ],
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
