import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/gallery_service.dart';
import 'package:hello_gallery/shared/models/gallery_item.dart';

void main() {
  test('scan returns folders and supported media only', () async {
    final root = await Directory.systemTemp.createTemp('local_gallery_test_');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/album').create();
    await File('${root.path}/photo.JPG').writeAsBytes(const [1]);
    await File('${root.path}/clip.mp4').writeAsBytes(const [1]);
    await File('${root.path}/notes.txt').writeAsString('ignore me');

    final items = await const GalleryService().scan(root.path);

    expect(items.whereType<GalleryFolder>(), hasLength(1));
    expect(items.whereType<MediaItem>(), hasLength(2));
    expect(items.map((item) => item.name), isNot(contains('notes.txt')));
  });

  test('recursive scan includes unvisited media in nested folders', () async {
    final root = await Directory.systemTemp.createTemp('local_gallery_tree_');
    addTearDown(() => root.delete(recursive: true));
    final nested = await Directory(
      '${root.path}/album/nested',
    ).create(recursive: true);
    await File('${root.path}/a.jpg').writeAsBytes(const [1]);
    await File('${root.path}/b.jpg').writeAsBytes(const [1]);
    await File('${nested.path}/c.mp4').writeAsBytes(const [1]);

    final media = await const GalleryService().scanMediaRecursively(root.path);

    expect(
      media.map((item) => item.name),
      containsAll(['a.jpg', 'b.jpg', 'c.mp4']),
    );
  });
}
