import 'package:path/path.dart' as path;

import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/media_management_repository.dart';
import 'create_folder.dart';

final class MediaTrashResult {
  const MediaTrashResult({required this.moved, required this.failed});

  final List<MediaItem> moved;
  final Map<MediaItem, Object> failed;
}

final class MoveMediaToTrash {
  const MoveMediaToTrash(this._repository);

  final MediaManagementRepository _repository;

  Future<MediaTrashResult> call({
    required String rootPath,
    required List<MediaItem> items,
  }) async {
    final root = path.normalize(rootPath);
    final uniqueItems = <String, MediaItem>{
      for (final item in items) path.normalize(item.path): item,
    }.values;
    final moved = <MediaItem>[];
    final failed = <MediaItem, Object>{};

    for (final item in uniqueItems) {
      try {
        final target = path.normalize(item.path);
        ensurePathInsideRoot(root, target);
        if (!await _repository.fileExists(target)) {
          throw ArgumentError('File no longer exists.');
        }
        await _repository.moveMediaToTrash(target);
        moved.add(item);
      } on Object catch (error) {
        failed[item] = error;
      }
    }
    return MediaTrashResult(
      moved: List.unmodifiable(moved),
      failed: Map.unmodifiable(failed),
    );
  }
}
