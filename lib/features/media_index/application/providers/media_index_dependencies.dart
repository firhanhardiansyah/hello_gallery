import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/local_file_watcher_service.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/services/file_watcher_service.dart';
import '../use_cases/watch_gallery_changes.dart';

final fileWatcherServiceProvider = Provider<FileWatcherService>(
  (ref) => const LocalFileWatcherService(),
);

final watchGalleryChangesProvider = Provider(
  (ref) => WatchGalleryChanges(ref.watch(fileWatcherServiceProvider)),
);

final galleryAutoSyncProvider = StreamProvider.autoDispose
    .family<FileChangeBatch, String>(
      (ref, rootPath) => ref.watch(watchGalleryChangesProvider)(rootPath),
    );
