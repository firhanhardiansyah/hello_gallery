import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/models/gallery_item.dart';

class GalleryCard extends StatelessWidget {
  const GalleryCard({
    required this.item,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final GalleryItem item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colorScheme.primary : Colors.transparent,
          width: selected ? 3 : 0,
        ),
      ),
      elevation: selected ? 5 : 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Preview(item: item)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Icon(
                    item is GalleryFolder
                        ? Icons.folder_rounded
                        : item.type == GalleryItemType.video
                        ? Icons.movie_rounded
                        : Icons.image_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    if (item case final GalleryFolder folder) {
      if (folder.previewPaths.isEmpty) {
        return const ColoredBox(
          color: Color(0xFF24242C),
          child: Center(child: Icon(Icons.folder_rounded, size: 52)),
        );
      }
      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        children: [
          for (final preview in folder.previewPaths)
            Image.file(File(preview), fit: BoxFit.cover, cacheWidth: 240),
        ],
      );
    }
    if (item case final MediaItem media when !media.isVideo) {
      return Image.file(
        File(media.path),
        fit: BoxFit.cover,
        cacheWidth: 420,
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }
    return const ColoredBox(
      color: Color(0xFF24242C),
      child: Center(child: Icon(Icons.play_circle_fill_rounded, size: 58)),
    );
  }
}
