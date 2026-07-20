import 'package:path/path.dart' as path;

import '../../domain/entities/gallery_item.dart';

typedef GalleryDirectoryLoader = Future<List<GalleryItem>> Function();

final class GalleryDirectoryCache {
  GalleryDirectoryCache({this.maxEntries = 256}) : assert(maxEntries > 0);

  final int maxEntries;
  final _entries = <String, List<GalleryItem>>{};
  final _inFlight = <String, Future<List<GalleryItem>>>{};
  int _generation = 0;

  Future<List<GalleryItem>> read(
    String directoryPath, {
    required GalleryDirectoryLoader load,
    bool forceRefresh = false,
  }) {
    final key = path.normalize(directoryPath);
    if (!forceRefresh) {
      final cached = get(directoryPath);
      if (cached != null) return Future.value(cached);
    }

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final generation = _generation;
    late final Future<List<GalleryItem>> request;
    request = Future.sync(load)
        .then((items) {
          final snapshot = List<GalleryItem>.unmodifiable(items);
          if (generation == _generation) {
            _entries[key] = snapshot;
            _evictOldestEntries();
          }
          return snapshot;
        })
        .whenComplete(() {
          if (identical(_inFlight[key], request)) _inFlight.remove(key);
        });
    _inFlight[key] = request;
    return request;
  }

  List<GalleryItem>? get(String directoryPath) {
    final key = path.normalize(directoryPath);
    final cached = _entries.remove(key);
    if (cached == null) return null;
    _entries[key] = cached;
    return cached;
  }

  void invalidate(String directoryPath) {
    _entries.remove(path.normalize(directoryPath));
  }

  void clear() {
    _generation++;
    _entries.clear();
    _inFlight.clear();
  }

  void _evictOldestEntries() {
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}
