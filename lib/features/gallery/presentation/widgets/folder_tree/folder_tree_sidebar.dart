import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/core/widgets/desktop_window_title_bar.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as path;

import '../../../application/providers/gallery_dependencies.dart';
import '../../states/media_drag_payload.dart';
import 'folder_tree_contents.dart';
import 'folder_tree_view.dart';

class FolderTreeSidebar extends ConsumerStatefulWidget {
  const FolderTreeSidebar({
    required this.rootPath,
    required this.currentFolderPath,
    required this.sort,
    required this.onMediaSelected,
    required this.onRefresh,
    required this.onChooseRootFolder,
    this.activeMediaPath,
    this.onFolderSelected,
    this.onRenameFolder,
    this.onDeleteFolder,
    this.onMediaDropped,
    this.onClose,
    this.syncRevision = 0,
    this.syncedDirectoryPaths = const {},
    this.windowPlatform,
    super.key,
  });

  final String rootPath;
  final String currentFolderPath;
  final String? activeMediaPath;
  final GallerySort sort;
  final VoidCallback? onRefresh;
  final VoidCallback onChooseRootFolder;
  final ValueChanged<String>? onFolderSelected;
  final ValueChanged<String>? onRenameFolder;
  final ValueChanged<String>? onDeleteFolder;
  final void Function(MediaDragPayload payload, String destinationPath)?
  onMediaDropped;
  final ValueChanged<MediaItem> onMediaSelected;
  final VoidCallback? onClose;
  final int syncRevision;
  final Set<String> syncedDirectoryPaths;
  final DesktopWindowPlatform? windowPlatform;

  @override
  ConsumerState<FolderTreeSidebar> createState() => _FolderTreeSidebarState();
}

class _FolderTreeSidebarState extends ConsumerState<FolderTreeSidebar> {
  final _scrollController = ScrollController();
  final _expandedPaths = <String>{};
  final _loadingPaths = <String>{};
  final _contentsByPath = <String, FolderTreeContents>{};
  final _revealKeys = <String, GlobalKey>{};
  int _revealGeneration = 0;
  int _syncGeneration = 0;
  final _pendingSyncPaths = <String>{};
  bool _syncInProgress = false;

  @override
  void initState() {
    super.initState();
    _expandedPaths.add(widget.rootPath);
    _revealActiveLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FolderTreeSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!path.equals(oldWidget.rootPath, widget.rootPath)) {
      _syncGeneration++;
      _expandedPaths
        ..clear()
        ..add(widget.rootPath);
      _loadingPaths.clear();
      _contentsByPath.clear();
      _revealKeys.clear();
      _pendingSyncPaths.clear();
    }
    if (oldWidget.syncRevision != widget.syncRevision) {
      _scheduleChangedFolders(widget.syncedDirectoryPaths);
    }
    final locationChanged =
        !_samePath(oldWidget.currentFolderPath, widget.currentFolderPath) ||
        !_samePath(oldWidget.activeMediaPath, widget.activeMediaPath);
    if (locationChanged || !_contentsByPath.containsKey(widget.rootPath)) {
      _revealActiveLocation();
    } else if (oldWidget.sort != widget.sort) {
      setState(() {});
    }
  }

  bool _samePath(String? left, String? right) {
    if (left == null || right == null) return left == right;
    return path.equals(left, right);
  }

  String get _targetFolderPath => widget.activeMediaPath == null
      ? widget.currentFolderPath
      : path.dirname(widget.activeMediaPath!);

  Future<void> _revealActiveLocation() async {
    final generation = ++_revealGeneration;
    final ancestors = _ancestorsTo(_targetFolderPath);
    for (final ancestor in ancestors) {
      if (generation != _revealGeneration) return;
      _expandedPaths.add(ancestor);
      await _loadFolder(ancestor);
    }
    if (!mounted || generation != _revealGeneration) return;
    setState(() {});
    final activeMediaPath = widget.activeMediaPath;
    _scheduleReveal(activeMediaPath ?? _targetFolderPath);
  }

  List<String> _ancestorsTo(String targetPath) {
    if (!path.equals(targetPath, widget.rootPath) &&
        !path.isWithin(widget.rootPath, targetPath)) {
      return [widget.rootPath];
    }
    final result = <String>[targetPath];
    var current = targetPath;
    while (!path.equals(current, widget.rootPath)) {
      final parent = path.dirname(current);
      if (path.equals(parent, current)) break;
      result.add(parent);
      current = parent;
    }
    return result.reversed.toList();
  }

  Future<void> _loadFolder(String folderPath) async {
    if (_contentsByPath.containsKey(folderPath) ||
        _loadingPaths.contains(folderPath)) {
      while (_loadingPaths.contains(folderPath)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return;
    }
    _loadingPaths.add(folderPath);
    if (mounted) setState(() {});
    var folders = <GalleryFolder>[];
    var media = <MediaItem>[];
    try {
      final entries = await ref.read(readGalleryDirectoryProvider)(folderPath);
      folders = entries.whereType<GalleryFolder>().toList();
      media = entries.whereType<MediaItem>().toList();
    } on Object {
      // Keep an empty section for inaccessible folders.
    }
    _contentsByPath[folderPath] = FolderTreeContents(
      folders: folders,
      media: media,
    );
    _loadingPaths.remove(folderPath);
    if (mounted) setState(() {});
  }

  void _scheduleChangedFolders(Set<String> directoryPaths) {
    _pendingSyncPaths.addAll(directoryPaths);
    if (!_syncInProgress) unawaited(_drainChangedFolders());
  }

  Future<void> _drainChangedFolders() async {
    _syncInProgress = true;
    final generation = _syncGeneration;
    final reader = ref.read(readGalleryDirectoryProvider);
    while (_pendingSyncPaths.isNotEmpty &&
        mounted &&
        generation == _syncGeneration) {
      final changedPaths = {..._pendingSyncPaths};
      _pendingSyncPaths.clear();
      final loadedPaths = _contentsByPath.keys
          .where(
            (loadedPath) => changedPaths.any(
              (changedPath) => path.equals(loadedPath, changedPath),
            ),
          )
          .toList();
      await Future.wait([
        for (final folderPath in loadedPaths)
          () async {
            try {
              final entries = await reader(folderPath, forceRefresh: true);
              if (!mounted || generation != _syncGeneration) return;
              _contentsByPath[folderPath] = FolderTreeContents(
                folders: entries.whereType<GalleryFolder>().toList(),
                media: entries.whereType<MediaItem>().toList(),
              );
            } on Object {
              // Keep the last snapshot while a file operation is in flight.
            }
          }(),
      ]);
      if (mounted && generation == _syncGeneration) setState(() {});
    }
    _syncInProgress = false;
    if (_pendingSyncPaths.isNotEmpty && mounted) {
      unawaited(_drainChangedFolders());
    }
  }

  Future<void> _toggleFolder(String folderPath) async {
    if (path.equals(folderPath, widget.rootPath)) return;
    if (_expandedPaths.remove(folderPath)) {
      setState(() {});
      return;
    }
    _expandedPaths.add(folderPath);
    await _loadFolder(folderPath);
    if (mounted) setState(() {});
  }

  bool get _hasExpandedFolders => _expandedPaths.any(
    (folderPath) => !path.equals(folderPath, widget.rootPath),
  );

  void _collapseFolders() {
    if (!_hasExpandedFolders) return;
    setState(() {
      _expandedPaths
        ..clear()
        ..add(widget.rootPath);
    });
    _scheduleReveal(widget.rootPath);
  }

  GlobalKey _revealKeyFor(String itemPath) {
    return _revealKeys.putIfAbsent(itemPath, GlobalKey.new);
  }

  void _scheduleReveal(String itemPath) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (path.equals(itemPath, widget.rootPath)) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      final targetContext = _revealKeyFor(itemPath).currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.35,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final rootFolderName = path.basename(path.normalize(widget.rootPath));
    final windowPlatform =
        widget.windowPlatform ?? currentDesktopWindowPlatform;
    final rootHeader = _buildRootHeader(context, rootFolderName);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (windowPlatform == DesktopWindowPlatform.macOS) ...[
            DesktopWindowTitleBar(
              platform: windowPlatform,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh,
              reserveMacOSWindowButtons: true,
              showWindowsCaptionControls: false,
              child: const SizedBox.shrink(),
            ),
            rootHeader,
          ] else if (windowPlatform == DesktopWindowPlatform.windows)
            DesktopWindowTitleBar(
              platform: windowPlatform,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh,
              showWindowsCaptionControls: false,
              child: rootHeader,
            )
          else
            rootHeader,
          Expanded(
            child: FolderTreeView(
              scrollController: _scrollController,
              rootPath: widget.rootPath,
              currentFolderPath: widget.currentFolderPath,
              activeMediaPath: widget.activeMediaPath,
              sort: widget.sort,
              expandedPaths: _expandedPaths,
              loadingPaths: _loadingPaths,
              contentsByPath: _contentsByPath,
              revealKeyFor: _revealKeyFor,
              onToggleFolder: _toggleFolder,
              onFolderSelected: widget.onFolderSelected,
              onRenameFolder: widget.onRenameFolder,
              onDeleteFolder: widget.onDeleteFolder,
              onMediaDropped: widget.onMediaDropped,
              onMediaSelected: widget.onMediaSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRootHeader(BuildContext context, String rootFolderName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: widget.rootPath,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap:
                      widget.onFolderSelected != null &&
                          !path.equals(
                            widget.currentFolderPath,
                            widget.rootPath,
                          )
                      ? () => widget.onFolderSelected!(widget.rootPath)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      rootFolderName.isEmpty ? widget.rootPath : rootFolderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Choose root folder',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onChooseRootFolder,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedFolderAdd,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onRefresh,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'Collapse folders',
            visualDensity: VisualDensity.compact,
            onPressed: _hasExpandedFolders ? _collapseFolders : null,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMenuCollapse,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
