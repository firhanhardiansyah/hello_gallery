import 'package:path/path.dart' as path;

enum FileChangeType { added, modified, removed }

class FileChange {
  const FileChange({required this.path, required this.type});

  final String path;
  final FileChangeType type;
}

class FileChangeBatch {
  FileChangeBatch({required this.rootPath, required List<FileChange> changes})
    : changes = List.unmodifiable(changes),
      affectedDirectoryPaths = _affectedDirectories(rootPath, changes);

  final String rootPath;
  final List<FileChange> changes;
  final Set<String> affectedDirectoryPaths;

  static Set<String> _affectedDirectories(
    String rootPath,
    List<FileChange> changes,
  ) {
    final normalizedRoot = path.normalize(rootPath);
    final directories = <String>{};
    for (final change in changes) {
      final changedPath = path.normalize(change.path);
      if (!path.equals(changedPath, normalizedRoot) &&
          !path.isWithin(normalizedRoot, changedPath)) {
        continue;
      }
      if (path.equals(changedPath, normalizedRoot)) {
        directories.add(normalizedRoot);
        continue;
      }
      final directParent = path.dirname(changedPath);
      _addWithinRoot(directories, normalizedRoot, directParent);
      _addWithinRoot(directories, normalizedRoot, path.dirname(directParent));
    }
    return Set.unmodifiable(directories);
  }

  static void _addWithinRoot(
    Set<String> directories,
    String rootPath,
    String candidate,
  ) {
    if (path.equals(candidate, rootPath) ||
        path.isWithin(rootPath, candidate)) {
      directories.add(candidate);
    }
  }
}
