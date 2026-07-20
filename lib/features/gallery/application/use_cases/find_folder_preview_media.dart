import 'dart:collection';

import 'package:hello_gallery/core/utils/natural_compare.dart';

import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';

typedef FolderPreviewCancellationCheck = bool Function();

final class FindFolderPreviewMedia {
  const FindFolderPreviewMedia(
    this._repository, {
    this.maximumMedia = 4,
    this.maximumVisitedFolders = 256,
  }) : assert(maximumMedia > 0),
       assert(maximumVisitedFolders > 0);

  final GalleryRepository _repository;
  final int maximumMedia;
  final int maximumVisitedFolders;

  Future<List<MediaItem>> call(
    String folderPath, {
    FolderPreviewCancellationCheck? isCancelled,
  }) async {
    final pendingFolders = Queue<String>()..add(folderPath);
    final previews = <MediaItem>[];
    var visitedFolders = 0;

    while (pendingFolders.isNotEmpty &&
        previews.length < maximumMedia &&
        visitedFolders < maximumVisitedFolders) {
      if (isCancelled?.call() ?? false) return const [];
      final currentPath = pendingFolders.removeFirst();
      visitedFolders++;
      List<GalleryItem> entries;
      try {
        entries = await _repository.readDirectory(currentPath);
      } on Object {
        continue;
      }
      if (isCancelled?.call() ?? false) return const [];

      final media = entries.whereType<MediaItem>().toList()
        ..sort((a, b) => naturalCompare(a.name, b.name));
      for (final item in media) {
        previews.add(item);
        if (previews.length == maximumMedia) break;
      }

      final folders = entries.whereType<GalleryFolder>().toList()
        ..sort((a, b) => naturalCompare(a.name, b.name));
      pendingFolders.addAll(folders.map((folder) => folder.path));
    }
    return previews;
  }
}
