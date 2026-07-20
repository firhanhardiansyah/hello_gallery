import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_index/application/use_cases/watch_gallery_changes.dart';
import 'package:hello_gallery/features/media_index/domain/entities/file_change.dart';
import 'package:hello_gallery/features/media_index/domain/services/file_watcher_service.dart';

void main() {
  test('debounces changes and reports only affected directories', () async {
    final watcher = _FakeFileWatcherService();
    final useCase = WatchGalleryChanges(
      watcher,
      debounceDuration: const Duration(milliseconds: 10),
    );
    final batchFuture = useCase('/gallery').first;
    await Future<void>.delayed(Duration.zero);

    watcher.add(
      const FileChange(
        path: '/gallery/Anime/cover.jpg',
        type: FileChangeType.modified,
      ),
    );
    watcher.add(
      const FileChange(
        path: '/gallery/Anime/video.mp4',
        type: FileChangeType.added,
      ),
    );

    final batch = await batchFuture;

    expect(batch.changes, hasLength(2));
    expect(batch.affectedDirectoryPaths, {'/gallery/Anime', '/gallery'});
  });

  test('marks the root as affected when the root itself changes', () {
    final batch = FileChangeBatch(
      rootPath: '/gallery',
      changes: const [
        FileChange(path: '/gallery', type: FileChangeType.removed),
      ],
    );

    expect(batch.affectedDirectoryPaths, {'/gallery'});
  });
}

final class _FakeFileWatcherService implements FileWatcherService {
  final _controller = StreamController<FileChange>();

  void add(FileChange change) => _controller.add(change);

  @override
  Stream<FileChange> watch(String rootPath) => _controller.stream;
}
