import 'package:flutter/material.dart';
import 'package:hello_gallery/core/utils/natural_compare.dart';
import 'package:path/path.dart' as path;

import '../../../domain/entities/gallery_item.dart';
import '../../../domain/value_objects/gallery_sort.dart';
import 'folder_header_delegate.dart';
import 'folder_tree_contents.dart';
import 'media_tree_tile.dart';

class FolderTreeView extends StatelessWidget {
  const FolderTreeView({
    required this.rootPath,
    required this.currentFolderPath,
    required this.sort,
    required this.expandedPaths,
    required this.loadingPaths,
    required this.contentsByPath,
    required this.revealKeyFor,
    required this.onToggleFolder,
    required this.onMediaSelected,
    this.activeMediaPath,
    this.onFolderSelected,
    super.key,
  });

  final String rootPath;
  final String currentFolderPath;
  final String? activeMediaPath;
  final GallerySort sort;
  final Set<String> expandedPaths;
  final Set<String> loadingPaths;
  final Map<String, FolderTreeContents> contentsByPath;
  final GlobalKey Function(String itemPath) revealKeyFor;
  final ValueChanged<String> onToggleFolder;
  final ValueChanged<String>? onFolderSelected;
  final ValueChanged<MediaItem> onMediaSelected;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ..._buildFolderSlivers(context, rootPath, 0),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  List<Widget> _buildFolderSlivers(
    BuildContext context,
    String folderPath,
    int depth,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final contents = contentsByPath[folderPath];
    final expanded = expandedPaths.contains(folderPath);
    final loading = loadingPaths.contains(folderPath);
    final media = [...?contents?.media]
      ..sort((a, b) => _compareMedia(a, b, sort));
    final folders = [...?contents?.folders]
      ..sort(
        (a, b) => naturalCompare(path.basename(a.path), path.basename(b.path)),
      );

    final sectionSlivers = <Widget>[
      SliverPersistentHeader(
        pinned: true,
        delegate: FolderHeaderDelegate(
          depth: depth,
          name: path.basename(folderPath),
          selected: path.equals(folderPath, currentFolderPath),
          expanded: expanded,
          loading: loading,
          surfaceColor: colorScheme.surfaceContainerHigh,
          overlappingSurfaceColor: colorScheme.surfaceContainerHighest,
          primaryColor: colorScheme.primary,
          foregroundColor: colorScheme.onSurface,
          onToggle: () => onToggleFolder(folderPath),
          onOpen: onFolderSelected == null
              ? null
              : () {
                  if (!expanded) onToggleFolder(folderPath);
                  onFolderSelected!(folderPath);
                },
        ),
      ),
      if (expanded && loading)
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
            final selected =
                activeMediaPath != null &&
                path.equals(activeMediaPath!, item.path);
            return KeyedSubtree(
              key: revealKeyFor(item.path),
              child: MediaTreeTile(
                media: item,
                depth: depth + 1,
                selected: selected,
                onTap: () => onMediaSelected(item),
              ),
            );
          },
        ),
    ];

    final slivers = <Widget>[SliverMainAxisGroup(slivers: sectionSlivers)];
    if (expanded && contents != null) {
      for (final child in folders) {
        slivers.addAll(_buildFolderSlivers(context, child.path, depth + 1));
      }
    }
    return slivers;
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
