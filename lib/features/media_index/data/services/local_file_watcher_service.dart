import 'package:watcher/watcher.dart';

import '../../domain/entities/file_change.dart';
import '../../domain/services/file_watcher_service.dart';

final class LocalFileWatcherService implements FileWatcherService {
  const LocalFileWatcherService();

  @override
  Stream<FileChange> watch(String rootPath) async* {
    final watcher = DirectoryWatcher(rootPath);
    await for (final event in watcher.events) {
      yield FileChange(path: event.path, type: _mapType(event.type));
    }
  }

  FileChangeType _mapType(ChangeType type) {
    if (type == ChangeType.ADD) return FileChangeType.added;
    if (type == ChangeType.REMOVE) return FileChangeType.removed;
    return FileChangeType.modified;
  }
}
