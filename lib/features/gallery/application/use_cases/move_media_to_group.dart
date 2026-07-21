import 'package:path/path.dart' as path;

import '../../domain/entities/media_grouping.dart';
import '../../domain/repositories/media_organization_repository.dart';

typedef GroupMediaProgressCallback = void Function(GroupMediaProgress progress);

final class MoveMediaToGroup {
  const MoveMediaToGroup(this._repository);

  final MediaOrganizationRepository _repository;

  Future<GroupMediaResult> call({
    required String sourceDirectoryPath,
    required String destinationPath,
    required List<String> fileNames,
    required GroupMediaProgressCallback onProgress,
  }) async {
    await _repository.createDirectory(destinationPath);

    var moved = 0;
    var skipped = 0;
    var failed = 0;
    final stopwatch = Stopwatch()..start();

    for (var index = 0; index < fileNames.length; index++) {
      final fileName = fileNames[index];
      final sourcePath = path.join(sourceDirectoryPath, fileName);
      final targetPath = path.join(destinationPath, fileName);
      try {
        if (await _repository.fileExists(targetPath)) {
          skipped++;
        } else if (!await _repository.fileExists(sourcePath)) {
          failed++;
        } else {
          await _repository.moveFile(sourcePath, targetPath);
          moved++;
        }
      } on Object {
        failed++;
      }

      final completed = index + 1;
      if (completed == fileNames.length ||
          stopwatch.elapsedMilliseconds >= 75) {
        onProgress(
          GroupMediaProgress(
            completed: completed,
            total: fileNames.length,
            currentFileName: fileName,
            moved: moved,
            skipped: skipped,
            failed: failed,
          ),
        );
        stopwatch.reset();
      }
    }

    return GroupMediaResult(
      destinationPath: destinationPath,
      moved: moved,
      skipped: skipped,
      failed: failed,
    );
  }
}
