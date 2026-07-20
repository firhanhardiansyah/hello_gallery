import 'dart:async';

import '../../domain/entities/file_change.dart';
import '../../domain/services/file_watcher_service.dart';

final class WatchGalleryChanges {
  const WatchGalleryChanges(
    this._watcher, {
    this.debounceDuration = const Duration(milliseconds: 250),
  });

  final FileWatcherService _watcher;
  final Duration debounceDuration;

  Stream<FileChangeBatch> call(String rootPath) {
    late final StreamController<FileChangeBatch> controller;
    StreamSubscription<FileChange>? subscription;
    Timer? debounceTimer;
    final pendingChanges = <FileChange>[];

    void emitPending() {
      debounceTimer?.cancel();
      debounceTimer = null;
      if (pendingChanges.isEmpty || controller.isClosed) return;
      controller.add(
        FileChangeBatch(rootPath: rootPath, changes: [...pendingChanges]),
      );
      pendingChanges.clear();
    }

    controller = StreamController<FileChangeBatch>(
      onListen: () {
        subscription = _watcher
            .watch(rootPath)
            .listen(
              (change) {
                pendingChanges.add(change);
                debounceTimer?.cancel();
                debounceTimer = Timer(debounceDuration, emitPending);
              },
              onError: controller.addError,
              onDone: () {
                emitPending();
                unawaited(controller.close());
              },
            );
      },
      onCancel: () async {
        debounceTimer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
