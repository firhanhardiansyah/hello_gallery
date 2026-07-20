import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/utils/natural_compare.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as path;

import '../../application/providers/gallery_dependencies.dart';

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
  final _contentsByPath = <String, _FolderContents>{};
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
    _contentsByPath[folderPath] = _FolderContents(
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

  List<Widget> _buildFolderSlivers(String folderPath, int depth) {
    final contents = _contentsByPath[folderPath];
    final expanded = _expandedPaths.contains(folderPath);
    final selected = path.equals(folderPath, widget.currentFolderPath);
    final media = [...?contents?.media]
      ..sort((a, b) => _compareMedia(a, b, widget.sort));
    final folders = [...?contents?.folders]
      ..sort(
        (a, b) => naturalCompare(path.basename(a.path), path.basename(b.path)),
      );

    final sectionSlivers = <Widget>[
      SliverPersistentHeader(
        pinned: true,
        delegate: _FolderHeaderDelegate(
          depth: depth,
          name: path.basename(folderPath),
          selected: selected,
          expanded: expanded,
          loading: _loadingPaths.contains(folderPath),
          onToggle: () => _toggleFolder(folderPath),
          onOpen: widget.onFolderSelected == null
              ? null
              : () {
                  if (!expanded) _toggleFolder(folderPath);
                  widget.onFolderSelected!(folderPath);
                },
        ),
      ),
      if (expanded && _loadingPaths.contains(folderPath))
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: LinearProgressIndicator(),
          ),
        ),
      if (expanded && media.isNotEmpty)
        SliverList.builder(
          itemCount: media.length,
          itemBuilder: (context, index) {
            final item = media[index];
            final active =
                widget.activeMediaPath != null &&
                path.equals(widget.activeMediaPath!, item.path);
            return KeyedSubtree(
              key: _revealKeyFor(item.path),
              child: _MediaTreeTile(
                media: item,
                depth: depth + 1,
                selected: active,
                onTap: () => widget.onMediaSelected(item),
              ),
            );
          },
        ),
    ];

    final slivers = <Widget>[SliverMainAxisGroup(slivers: sectionSlivers)];
    if (expanded && contents != null) {
      for (final child in folders) {
        slivers.addAll(_buildFolderSlivers(child.path, depth + 1));
      }
    }
    return slivers;
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
            child: CustomScrollView(
              slivers: [
                ..._buildFolderSlivers(widget.rootPath, 0),
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FolderHeaderDelegate({
    required this.depth,
    required this.name,
    required this.selected,
    required this.expanded,
    required this.loading,
    required this.onToggle,
    required this.onOpen,
  });

  final int depth;
  final String name;
  final bool selected;
  final bool expanded;
  final bool loading;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Material(
        color: overlapsContent
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHigh,
        elevation: overlapsContent ? 2 : 0,
        child: Padding(
          padding: EdgeInsets.only(left: 8 + (depth * 14), right: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: expanded ? 'Collapse folder' : 'Expand folder',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : HugeIcon(
                        icon: expanded
                            ? HugeIcons.strokeRoundedArrowDown01
                            : HugeIcons.strokeRoundedArrowRight01,
                      ),
              ),
              HugeIcon(
                icon: expanded
                    ? HugeIcons.strokeRoundedFolderOpen
                    : HugeIcons.strokeRoundedFolder01,
                size: 20,
                color: selected ? colorScheme.primary : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onOpen ?? onToggle,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: selected
                          ? TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FolderHeaderDelegate oldDelegate) {
    return depth != oldDelegate.depth ||
        name != oldDelegate.name ||
        selected != oldDelegate.selected ||
        expanded != oldDelegate.expanded ||
        loading != oldDelegate.loading;
  }
}

class _MediaTreeTile extends StatelessWidget {
  const _MediaTreeTile({
    required this.media,
    required this.depth,
    required this.selected,
    required this.onTap,
  });

  final MediaItem media;
  final int depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: 18 + (depth * 14), right: 8, bottom: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.72)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border(
            left: BorderSide(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            selected: selected,
            dense: true,
            contentPadding: const EdgeInsets.only(left: 10, right: 8),
            leading: HugeIcon(
              icon: media.isVideo
                  ? HugeIcons.strokeRoundedVideo01
                  : HugeIcons.strokeRoundedImage01,
              size: 20,
              color: selected ? colorScheme.primary : null,
            ),
            title: Text(
              media.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: selected
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
            trailing: selected
                ? HugeIcon(
                    icon: media.isVideo
                        ? HugeIcons.strokeRoundedPlayCircle
                        : HugeIcons.strokeRoundedView,
                    color: colorScheme.primary,
                    size: 20,
                  )
                : null,
            onTap: onTap,
          ),
        ),
      ),
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

class _FolderContents {
  const _FolderContents({this.folders = const [], this.media = const []});

  final List<GalleryFolder> folders;
  final List<MediaItem> media;
}
