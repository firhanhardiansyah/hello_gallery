import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as path;

import '../../application/providers/gallery_dependencies.dart';
import 'folder_tree/folder_tree_contents.dart';
import 'folder_tree/folder_tree_view.dart';

class FolderTreeSidebar extends ConsumerStatefulWidget {
  const FolderTreeSidebar({
    required this.rootPath,
    required this.currentFolderPath,
    required this.sort,
    required this.onMediaSelected,
    this.activeMediaPath,
    this.onFolderSelected,
    this.onClose,
    super.key,
  });

  final String rootPath;
  final String currentFolderPath;
  final String? activeMediaPath;
  final GallerySort sort;
  final ValueChanged<String>? onFolderSelected;
  final ValueChanged<MediaItem> onMediaSelected;
  final VoidCallback? onClose;

  @override
  ConsumerState<FolderTreeSidebar> createState() => _FolderTreeSidebarState();
}

class _FolderTreeSidebarState extends ConsumerState<FolderTreeSidebar> {
  final _expandedPaths = <String>{};
  final _loadingPaths = <String>{};
  final _contentsByPath = <String, FolderTreeContents>{};
  final _revealKeys = <String, GlobalKey>{};
  int _revealGeneration = 0;

  @override
  void initState() {
    super.initState();
    _expandedPaths.add(widget.rootPath);
    _revealActiveLocation();
  }

  @override
  void didUpdateWidget(covariant FolderTreeSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!path.equals(oldWidget.rootPath, widget.rootPath)) {
      _expandedPaths
        ..clear()
        ..add(widget.rootPath);
      _loadingPaths.clear();
      _contentsByPath.clear();
      _revealKeys.clear();
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
    if (activeMediaPath != null) _scheduleReveal(activeMediaPath);
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

  Future<void> _toggleFolder(String folderPath) async {
    if (_expandedPaths.remove(folderPath)) {
      setState(() {});
      return;
    }
    _expandedPaths.add(folderPath);
    await _loadFolder(folderPath);
    if (mounted) setState(() {});
  }

  GlobalKey _revealKeyFor(String itemPath) {
    return _revealKeys.putIfAbsent(itemPath, GlobalKey.new);
  }

  void _scheduleReveal(String itemPath) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
            child: Row(
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedFolderTree),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Folders & Media',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: 'Close sidebar',
                    onPressed: widget.onClose,
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FolderTreeView(
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
              onMediaSelected: widget.onMediaSelected,
            ),
          ),
        ],
      ),
    );
  }
}
