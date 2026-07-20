import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/core/utils/natural_compare.dart';
import 'package:path/path.dart' as path;

import '../../../domain/entities/gallery_item.dart';
import '../../../domain/rules/gallery_item_sort_rules.dart';
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
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.lg)),
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
    final isRoot = path.equals(folderPath, rootPath);
    final selectedFolder = path.equals(folderPath, currentFolderPath);
    final expanded = isRoot || expandedPaths.contains(folderPath);
    final loading = loadingPaths.contains(folderPath);
    final media = [...?contents?.media]
      ..sort((a, b) => GalleryItemSortRules.compareMedia(a, b, sort));
    final folders = [...?contents?.folders]
      ..sort(
        (a, b) => naturalCompare(path.basename(a.path), path.basename(b.path)),
      );

    final sectionSlivers = <Widget>[
      if (!isRoot)
        SliverPersistentHeader(
          pinned: true,
          delegate: FolderHeaderDelegate(
            depth: depth,
            name: path.basename(folderPath),
            selected: selectedFolder,
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
                    if (selectedFolder) {
                      onToggleFolder(folderPath);
                      return;
                    }
                    if (!expanded) onToggleFolder(folderPath);
                    onFolderSelected!(folderPath);
                  },
          ),
        ),
      if (expanded && loading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
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
                depth: isRoot ? depth : depth + 1,
                selected: selected,
                onTap: () => onMediaSelected(item),
              ),
            );
          },
        ),
    ];

    final slivers = <Widget>[
      if (sectionSlivers.isNotEmpty)
        SliverMainAxisGroup(slivers: sectionSlivers),
    ];
    if (expanded && contents != null) {
      for (final child in folders) {
        slivers.addAll(
          _buildFolderSlivers(context, child.path, isRoot ? depth : depth + 1),
        );
      }
    }
    return slivers;
  }
}
