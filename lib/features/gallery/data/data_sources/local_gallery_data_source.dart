import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import '../../domain/rules/media_type_rules.dart';

class LocalGalleryDataSource {
  const LocalGalleryDataSource();

  Future<List<GalleryItem>> scan(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw FileSystemException('Folder no longer exists', directoryPath);
    }

    final items = <GalleryItem>[];
    await for (final entity in directory.list(followLinks: false)) {
      try {
        final stat = await entity.stat();
        final name = path.basename(entity.path);
        if (entity is Directory) {
          items.add(
            GalleryFolder(
              path: entity.path,
              name: name,
              modifiedAt: stat.modified,
              previewPaths: await _folderPreviews(entity),
            ),
          );
        } else if (entity is File) {
          final type = MediaTypeRules.fromPath(name);
          if (type != null) {
            items.add(
              MediaItem(
                path: entity.path,
                name: name,
                modifiedAt: stat.modified,
                mediaType: type,
                sizeBytes: stat.size,
              ),
            );
          }
        }
      } on FileSystemException {
        // A file can disappear while a directory is being scanned.
      }
    }
    return items;
  }

  Future<List<MediaItem>> scanMediaRecursively(String rootPath) async {
    final directory = Directory(rootPath);
    if (!await directory.exists()) {
      throw FileSystemException('Folder no longer exists', rootPath);
    }

    final media = <MediaItem>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final type = MediaTypeRules.fromPath(entity.path);
      if (type == null) continue;
      try {
        final stat = await entity.stat();
        media.add(
          MediaItem(
            path: entity.path,
            name: path.basename(entity.path),
            modifiedAt: stat.modified,
            mediaType: type,
            sizeBytes: stat.size,
          ),
        );
      } on FileSystemException {
        // Ignore entries removed while the recursive scan is running.
      }
    }
    return media;
  }

  Future<List<String>> _folderPreviews(Directory directory) async {
    final previews = <String>[];
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File &&
            MediaTypeRules.imageExtensions.contains(
              path.extension(entity.path).toLowerCase(),
            )) {
          previews.add(entity.path);
          if (previews.length == 4) break;
        }
      }
    } on FileSystemException {
      return const [];
    }
    return previews;
  }
}
