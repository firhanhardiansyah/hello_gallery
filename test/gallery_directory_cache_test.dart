import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/services/gallery_directory_cache.dart';

void main() {
  test('reuses cached directory results', () async {
    final cache = GalleryDirectoryCache();
    var loadCount = 0;

    Future<List<Never>> load() async {
      loadCount++;
      return [];
    }

    await cache.read('/gallery', load: load);
    await cache.read('/gallery', load: load);

    expect(loadCount, 1);
  });

  test('coalesces concurrent reads for the same directory', () async {
    final cache = GalleryDirectoryCache();
    final completer = Completer<List<Never>>();
    var loadCount = 0;

    Future<List<Never>> load() {
      loadCount++;
      return completer.future;
    }

    final first = cache.read('/gallery', load: load);
    final second = cache.read('/gallery', load: load);
    completer.complete([]);
    await Future.wait([first, second]);

    expect(loadCount, 1);
  });

  test('force refresh reloads and replaces a cached directory', () async {
    final cache = GalleryDirectoryCache();
    var loadCount = 0;

    Future<List<Never>> load() async {
      loadCount++;
      return [];
    }

    await cache.read('/gallery', load: load);
    await cache.read('/gallery', load: load, forceRefresh: true);

    expect(loadCount, 2);
  });

  test('evicts the least recently used directory', () async {
    final cache = GalleryDirectoryCache(maxEntries: 1);
    var loadCount = 0;

    Future<List<Never>> load() async {
      loadCount++;
      return [];
    }

    await cache.read('/gallery/one', load: load);
    await cache.read('/gallery/two', load: load);
    await cache.read('/gallery/one', load: load);

    expect(loadCount, 3);
  });
}
