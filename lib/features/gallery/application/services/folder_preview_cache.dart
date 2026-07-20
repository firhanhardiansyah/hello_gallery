import 'package:path/path.dart' as path;

import '../../domain/entities/gallery_item.dart';

final class FolderPreviewCache {
  FolderPreviewCache({this.maxEntries = 256}) : assert(maxEntries > 0);

  final int maxEntries;
  final _entries = <String, List<MediaItem>>{};

  List<MediaItem>? get(String folderPath) {
    final key = path.normalize(folderPath);
    final cached = _entries.remove(key);
    if (cached == null) return null;
    _entries[key] = cached;
    return cached;
  }

  void put(String folderPath, List<MediaItem> items) {
    final key = path.normalize(folderPath);
    _entries[key] = List.unmodifiable(items);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidate(String folderPath) {
    _entries.remove(path.normalize(folderPath));
  }

  void clear() => _entries.clear();
}
