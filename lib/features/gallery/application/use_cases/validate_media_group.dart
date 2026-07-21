import 'package:path/path.dart' as path;

import '../../domain/entities/gallery_item.dart';
import '../../domain/entities/media_grouping.dart';
import 'read_gallery_directory.dart';

final class ValidateMediaGroup {
  const ValidateMediaGroup(this._readGalleryDirectory);

  final ReadGalleryDirectory _readGalleryDirectory;

  Future<GroupMediaValidation> call(GroupMediaRequest request) async {
    final destinationPath = path.join(
      request.destinationParentPath,
      request.groupName.trim(),
    );
    final requestError = _validateRequest(request, destinationPath);
    if (requestError != null) {
      return GroupMediaValidation(
        destinationPath: destinationPath,
        readyFileNames: const [],
        missingFileNames: const [],
        invalidFileNames: const [],
        errorMessage: requestError,
      );
    }

    final normalized = <String>[];
    final invalid = <String>[];
    final seen = <String>{};
    for (final rawName in request.fileNames) {
      final name = rawName.trim();
      if (name.isEmpty || !seen.add(name)) continue;
      if (path.isAbsolute(name) || path.basename(name) != name) {
        invalid.add(name);
      } else {
        normalized.add(name);
      }
    }

    final entries = await _readGalleryDirectory(request.sourceDirectoryPath);
    final availableNames = {
      for (final item in entries.whereType<MediaItem>()) item.name,
    };
    final ready = <String>[];
    final missing = <String>[];
    for (final name in normalized) {
      if (availableNames.contains(name)) {
        ready.add(name);
      } else {
        missing.add(name);
      }
    }

    return GroupMediaValidation(
      destinationPath: destinationPath,
      readyFileNames: ready,
      missingFileNames: missing,
      invalidFileNames: invalid,
    );
  }

  String? _validateRequest(GroupMediaRequest request, String destinationPath) {
    final root = path.normalize(request.rootPath);
    final source = path.normalize(request.sourceDirectoryPath);
    final destinationParent = path.normalize(request.destinationParentPath);
    final groupName = request.groupName.trim();

    if (!_isInside(root, source)) {
      return 'Source folder must be inside the gallery root.';
    }
    if (!_isInside(root, destinationParent)) {
      return 'Destination folder must be inside the gallery root.';
    }
    if (groupName.isEmpty) return 'Enter a group folder name.';
    if (path.isAbsolute(groupName) ||
        path.basename(groupName) != groupName ||
        groupName == '.' ||
        groupName == '..') {
      return 'Group name must be a single folder name.';
    }
    if (!_isInside(root, destinationPath)) {
      return 'Destination folder must be inside the gallery root.';
    }
    if (path.equals(source, destinationPath)) {
      return 'Destination must be different from the source folder.';
    }
    return null;
  }

  bool _isInside(String root, String candidate) {
    return path.equals(root, candidate) || path.isWithin(root, candidate);
  }
}
