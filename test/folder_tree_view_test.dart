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
    final childKey = GlobalKey();
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
            revealKeyFor: (itemPath) =>
                itemPath == childPath ? childKey : GlobalKey(),
            onToggleFolder: (_) {},
            onMediaSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Wallpapers'), findsNothing);
    expect(find.text('Anime'), findsOneWidget);
    expect(childKey.currentContext, isNotNull);
  });

  testWidgets('keeps folder toggle separate from the row open action', (
    tester,
  ) async {
    const rootPath = '/gallery/Wallpapers';
    const childPath = '$rootPath/Anime';
    String? toggledPath;
    String? openedPath;
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
            onToggleFolder: (path) => toggledPath = path,
            onFolderSelected: (path) => openedPath = path,
            onMediaSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Expand folder'));

    expect(toggledPath, childPath);
    expect(openedPath, isNull);

    await tester.tap(find.text('Anime'));

    expect(openedPath, childPath);
  });

  testWidgets('toggles an active folder when its row is tapped', (
    tester,
  ) async {
    const rootPath = '/gallery/Wallpapers';
    const childPath = '$rootPath/One Piece';
    String? toggledPath;
    String? openedPath;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderTreeView(
            rootPath: rootPath,
            currentFolderPath: childPath,
            sort: GallerySort.nameAscending,
            expandedPaths: const {rootPath, childPath},
            loadingPaths: const {},
            contentsByPath: {
              rootPath: FolderTreeContents(
                folders: [
                  GalleryFolder(
                    path: childPath,
                    name: 'One Piece',
                    modifiedAt: DateTime(2026),
                  ),
                ],
              ),
              childPath: const FolderTreeContents(),
            },
            revealKeyFor: (_) => GlobalKey(),
            onToggleFolder: (path) => toggledPath = path,
            onFolderSelected: (path) => openedPath = path,
            onMediaSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('One Piece'));

    expect(toggledPath, childPath);
    expect(openedPath, isNull);
  });

  testWidgets('shows the loaded folder item count in a badge', (tester) async {
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
              childPath: FolderTreeContents(
                folders: [
                  GalleryFolder(
                    path: '$childPath/Movies',
                    name: 'Movies',
                    modifiedAt: DateTime(2026),
                  ),
                ],
                media: [
                  MediaItem(
                    path: '$childPath/cover.jpg',
                    name: 'cover.jpg',
                    modifiedAt: DateTime(2026),
                    mediaType: GalleryItemType.image,
                  ),
                ],
              ),
            },
            revealKeyFor: (_) => GlobalKey(),
            onToggleFolder: (_) {},
            onMediaSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(Badge), findsOneWidget);
    final badge = tester.widget<Badge>(find.byType(Badge));
    final colorScheme = Theme.of(
      tester.element(find.byType(FolderTreeView)),
    ).colorScheme;
    expect(badge.backgroundColor, colorScheme.primary);
    expect(badge.textColor, colorScheme.onPrimary);
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );
  });
}
