import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_card.dart';

void main() {
  testWidgets('uses one full preview for a folder with one item', (
    tester,
  ) async {
    await _pumpFolderCard(tester, 1);

    final preview = tester.getRect(_previewFinder(0));
    expect(preview.width, 260);
  });

  testWidgets('stacks two folder previews vertically', (tester) async {
    await _pumpFolderCard(tester, 2);

    final top = tester.getRect(_previewFinder(0));
    final bottom = tester.getRect(_previewFinder(1));
    expect(top.left, bottom.left);
    expect(top.width, bottom.width);
    expect(top.bottom, bottom.top);
  });

  testWidgets('places one preview above two previews for three items', (
    tester,
  ) async {
    await _pumpFolderCard(tester, 3);

    final top = tester.getRect(_previewFinder(0));
    final bottomLeft = tester.getRect(_previewFinder(1));
    final bottomRight = tester.getRect(_previewFinder(2));
    expect(top.width, greaterThan(bottomLeft.width));
    expect(top.bottom, bottomLeft.top);
    expect(bottomLeft.top, bottomRight.top);
    expect(bottomLeft.right, bottomRight.left);
  });

  testWidgets('limits folder previews to a two by two grid', (tester) async {
    await _pumpFolderCard(tester, 5);

    final topLeft = tester.getRect(_previewFinder(0));
    final topRight = tester.getRect(_previewFinder(1));
    final bottomLeft = tester.getRect(_previewFinder(2));
    final bottomRight = tester.getRect(_previewFinder(3));
    expect(topLeft.top, topRight.top);
    expect(bottomLeft.top, bottomRight.top);
    expect(topLeft.bottom, bottomLeft.top);
    expect(topLeft.right, topRight.left);
    expect(_previewFinder(4), findsNothing);
  });
}

Future<void> _pumpFolderCard(WidgetTester tester, int previewCount) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 260,
              height: 210,
              child: GalleryCard(
                item: GalleryFolder(
                  path: '/gallery/album',
                  name: 'Album',
                  modifiedAt: DateTime(2026),
                  previewItems: [
                    for (var index = 0; index < previewCount; index++)
                      MediaItem(
                        path: '/gallery/album/image-$index.jpg',
                        name: 'image-$index.jpg',
                        modifiedAt: DateTime(2026),
                        mediaType: GalleryItemType.image,
                      ),
                  ],
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _previewFinder(int index) =>
    find.byKey(ValueKey('folder-preview:/gallery/album/image-$index.jpg'));
