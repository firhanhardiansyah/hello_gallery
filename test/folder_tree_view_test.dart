import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/folder_tree/folder_tree_contents.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/folder_tree/folder_tree_view.dart';

void main() {
  testWidgets('hides the root header and shows its child folders', (
    tester,
  ) async {
    const rootPath = '/gallery/Wallpapers';
    const childPath = '$rootPath/Anime';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderTreeView(
            rootPath: rootPath,
            currentFolderPath: rootPath,
            sort: GallerySort.nameAscending,
            expandedPaths: const {rootPath},
            loadingPaths: const {},
            contentsByPath: {
              rootPath: FolderTreeContents(
                folders: [
                  GalleryFolder(
                    path: childPath,
                    name: 'Anime',
                    modifiedAt: DateTime(2026),
                  ),
                ],
              ),
              childPath: const FolderTreeContents(),
            },
            revealKeyFor: (_) => GlobalKey(),
            onToggleFolder: (_) {},
            onMediaSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Wallpapers'), findsNothing);
    expect(find.text('Anime'), findsOneWidget);
  });
}
