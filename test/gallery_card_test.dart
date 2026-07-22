import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/gallery/application/providers/gallery_dependencies.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_card.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

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

  testWidgets('offers rename and trash actions on secondary click', (
    tester,
  ) async {
    var renamed = false;
    var deleted = false;
    await _pumpFolderCard(
      tester,
      0,
      onRenameFolder: () => renamed = true,
      onDeleteFolder: () => deleted = true,
    );

    await tester.tap(find.byType(GalleryCard), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Move to Trash'), findsOneWidget);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(renamed, isTrue);
    expect(deleted, isFalse);
  });

  testWidgets('shows a prominent border and check for selected cards', (
    tester,
  ) async {
    await _pumpFolderCard(tester, 0, selected: true);

    expect(
      find.byKey(const ValueKey('gallery-card-selection-border')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gallery-card-selection-check')),
      findsOneWidget,
    );
  });

  testWidgets('shows keyboard focus without selection check', (tester) async {
    await _pumpFolderCard(tester, 0, focused: true);

    expect(
      find.byKey(const ValueKey('gallery-card-focus-border')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gallery-card-selection-check')),
      findsNothing,
    );
  });
}

Future<void> _pumpFolderCard(
  WidgetTester tester,
  int previewCount, {
  VoidCallback? onRenameFolder,
  VoidCallback? onDeleteFolder,
  bool selected = false,
  bool focused = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        folderPreviewProvider.overrideWith(
          (ref, folder) => Future.value([
            for (var index = 0; index < previewCount; index++)
              MediaItem(
                path: '/gallery/album/image-$index.jpg',
                name: 'image-$index.jpg',
                modifiedAt: DateTime(2026),
                mediaType: GalleryItemType.image,
              ),
          ]),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.light,
        ),
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
                ),
                onTap: () {},
                selected: selected,
                focused: focused,
                onRenameFolder: onRenameFolder,
                onDeleteFolder: onDeleteFolder,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _previewFinder(int index) =>
    find.byKey(ValueKey('folder-preview:/gallery/album/image-$index.jpg'));
