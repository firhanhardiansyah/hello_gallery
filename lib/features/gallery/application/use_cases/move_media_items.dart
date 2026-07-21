import 'package:path/path.dart' as path;

import '../../domain/entities/gallery_item.dart';
import '../../domain/entities/media_move.dart';
import '../../domain/repositories/media_organization_repository.dart';

typedef MediaMoveProgressCallback = void Function(MediaMoveProgress progress);

final class MoveMediaItems {
  const MoveMediaItems(this._repository);

  final MediaOrganizationRepository _repository;

  Future<MediaMoveResult> call({
    required List<MediaItem> items,
    required String destinationPath,
    required MediaMoveProgressCallback onProgress,
  }) async {
    var moved = 0;
    var skipped = 0;
    var failed = 0;
    final stopwatch = Stopwatch()..start();

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final targetPath = path.join(destinationPath, item.name);
      try {
        if (path.equals(path.dirname(item.path), destinationPath) ||
            await _repository.fileExists(targetPath)) {
          skipped++;
        } else if (!await _repository.fileExists(item.path)) {
          failed++;
        } else {
          await _repository.moveFile(item.path, targetPath);
          moved++;
        }
      } on Object {
        failed++;
      }

      final completed = index + 1;
      if (completed == items.length || stopwatch.elapsedMilliseconds >= 75) {
        onProgress(
          MediaMoveProgress(
            completed: completed,
            total: items.length,
            currentFileName: item.name,
            moved: moved,
            skipped: skipped,
            failed: failed,
          ),
        );
        stopwatch.reset();
      }
    }

    return MediaMoveResult(
      destinationPath: destinationPath,
      moved: moved,
      skipped: skipped,
      failed: failed,
    );
  }
}
