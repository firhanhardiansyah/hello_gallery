import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../shared/models/gallery_item.dart';
import '../../../shared/models/gallery_sort.dart';
import '../../../shared/utils/natural_compare.dart';
import '../gallery_service.dart';

class FolderTreeSidebar extends StatelessWidget {
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
                const Icon(Icons.account_tree_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Folders & Media',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Close sidebar',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                _FolderNode(
                  directory: Directory(rootPath),
                  currentFolderPath: currentFolderPath,
                  activeMediaPath: activeMediaPath,
                  sort: sort,
                  onFolderSelected: onFolderSelected,
                  onMediaSelected: onMediaSelected,
                  initiallyExpanded: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderNode extends StatefulWidget {
  const _FolderNode({
    required this.directory,
    required this.currentFolderPath,
    required this.activeMediaPath,
    required this.sort,
    required this.onFolderSelected,
    required this.onMediaSelected,
    this.initiallyExpanded = false,
  });

  final Directory directory;
  final String currentFolderPath;
  final String? activeMediaPath;
  final GallerySort sort;
  final ValueChanged<String>? onFolderSelected;
  final ValueChanged<MediaItem> onMediaSelected;
  final bool initiallyExpanded;

  @override
  State<_FolderNode> createState() => _FolderNodeState();
}

class _FolderNodeState extends State<_FolderNode> {
  Future<_FolderContents>? _contents;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) _contents = _readContents();
  }

  Future<_FolderContents> _readContents() async {
    try {
      final folders = <Directory>[];
      final media = <MediaItem>[];
      await for (final entity in widget.directory.list(followLinks: false)) {
        if (entity is Directory) {
          folders.add(entity);
          continue;
        }
        if (entity is! File) continue;
        final extension = path.extension(entity.path).toLowerCase();
        final mediaType = GalleryService.imageExtensions.contains(extension)
            ? GalleryItemType.image
            : GalleryService.videoExtensions.contains(extension)
            ? GalleryItemType.video
            : null;
        if (mediaType == null) continue;
        try {
          final stat = await entity.stat();
          media.add(
            MediaItem(
              path: entity.path,
              name: path.basename(entity.path),
              modifiedAt: stat.modified,
              mediaType: mediaType,
              sizeBytes: stat.size,
            ),
          );
        } on FileSystemException {
          // The entry may disappear while the tree is loading.
        }
      }
      folders.sort(
        (a, b) => naturalCompare(path.basename(a.path), path.basename(b.path)),
      );
      media.sort((a, b) => _compareMedia(a, b, widget.sort));
      return _FolderContents(folders: folders, media: media);
    } on FileSystemException {
      return const _FolderContents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFolder = path.equals(
      widget.directory.path,
      widget.currentFolderPath,
    );
    final title = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        path.basename(widget.directory.path),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: selectedFolder
            ? TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              )
            : null,
      ),
    );
    return ExpansionTile(
      key: PageStorageKey(widget.directory.path),
      initiallyExpanded: widget.initiallyExpanded,
      tilePadding: const EdgeInsets.only(left: 12, right: 8),
      childrenPadding: const EdgeInsets.only(left: 14),
      leading: Icon(
        selectedFolder ? Icons.folder_open_rounded : Icons.folder_rounded,
        color: selectedFolder ? Theme.of(context).colorScheme.primary : null,
      ),
      title: widget.onFolderSelected == null
          ? title
          : Builder(
              builder: (tileContext) => InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  ExpansibleController.of(tileContext).expand();
                  widget.onFolderSelected!(widget.directory.path);
                },
                child: title,
              ),
            ),
      onExpansionChanged: (expanded) {
        if (expanded && _contents == null) {
          _contents = _readContents();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
      },
      children: [
        if (_contents case final contents?)
          FutureBuilder<_FolderContents>(
            future: contents,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                );
              }
              return Column(
                children: [
                  for (final child
                      in snapshot.data?.folders ?? const <Directory>[])
                    _FolderNode(
                      directory: child,
                      currentFolderPath: widget.currentFolderPath,
                      activeMediaPath: widget.activeMediaPath,
                      sort: widget.sort,
                      onFolderSelected: widget.onFolderSelected,
                      onMediaSelected: widget.onMediaSelected,
                    ),
                  for (final media
                      in snapshot.data?.media ?? const <MediaItem>[])
                    _MediaTreeTile(
                      media: media,
                      selected:
                          widget.activeMediaPath != null &&
                          path.equals(widget.activeMediaPath!, media.path),
                      onTap: () => widget.onMediaSelected(media),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _MediaTreeTile extends StatelessWidget {
  const _MediaTreeTile({
    required this.media,
    required this.selected,
    required this.onTap,
  });

  final MediaItem media;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 8, bottom: 2),
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
        child: ListTile(
          selected: selected,
          dense: true,
          contentPadding: const EdgeInsets.only(left: 10, right: 8),
          leading: Icon(
            media.isVideo ? Icons.movie_outlined : Icons.image_outlined,
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
              ? Icon(
                  media.isVideo
                      ? Icons.play_circle_fill_rounded
                      : Icons.visibility_rounded,
                  color: colorScheme.primary,
                  size: 20,
                )
              : null,
          onTap: onTap,
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

  final List<Directory> folders;
  final List<MediaItem> media;
}
