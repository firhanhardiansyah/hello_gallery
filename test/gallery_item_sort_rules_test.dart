import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/rules/gallery_item_sort_rules.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';

void main() {
  final older = MediaItem(
    path: '/gallery/video2.mp4',
    name: 'video2.mp4',
    modifiedAt: DateTime(2025),
    mediaType: GalleryItemType.video,
  );
  final newer = MediaItem(
    path: '/gallery/video10.mp4',
    name: 'video10.mp4',
    modifiedAt: DateTime(2026),
    mediaType: GalleryItemType.video,
  );
  final olderFolder = GalleryFolder(
    path: '/gallery/Folder 2',
    name: 'Folder 2',
    modifiedAt: DateTime(2025),
  );
  final newerFolder = GalleryFolder(
    path: '/gallery/Folder 10',
    name: 'Folder 10',
    modifiedAt: DateTime(2026),
  );

  test('sorts media names using natural order', () {
    final items = [newer, older]
      ..sort(
        (left, right) => GalleryItemSortRules.compareMedia(
          left,
          right,
          GallerySort.nameAscending,
        ),
      );

    expect(items, [older, newer]);
  });

  test('sorts newest media first', () {
    final items = [older, newer]
      ..sort(
        (left, right) =>
            GalleryItemSortRules.compareMedia(left, right, GallerySort.newest),
      );

    expect(items, [newer, older]);
  });

  test('sorts folder names using natural order', () {
    final items = [newerFolder, olderFolder]
      ..sort(
        (left, right) => GalleryItemSortRules.compareFolders(
          left,
          right,
          GallerySort.nameAscending,
        ),
      );

    expect(items, [olderFolder, newerFolder]);
  });

  test('sorts newest folders first', () {
    final items = [olderFolder, newerFolder]
      ..sort(
        (left, right) => GalleryItemSortRules.compareFolders(
          left,
          right,
          GallerySort.newest,
        ),
      );

    expect(items, [newerFolder, olderFolder]);
  });
}
