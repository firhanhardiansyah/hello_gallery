import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/core/widgets/desktop_window_title_bar.dart';
import 'package:hello_gallery/features/gallery/application/providers/gallery_dependencies.dart';
import 'package:hello_gallery/features/gallery/application/services/gallery_directory_cache.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/read_gallery_directory.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/folder_tree/folder_tree_sidebar.dart';

void main() {
  testWidgets('scrolls to the active folder when navigation changes', (
    tester,
  ) async {
    const rootPath = '/gallery/Wallpapers';
    const targetPath = '$rootPath/Studio Ghibli';
    final repository = _FolderTreeRepository(rootPath, targetPath);
    var refreshCount = 0;
    var chooseRootCount = 0;
    final container = ProviderContainer(
      overrides: [
        readGalleryDirectoryProvider.overrideWithValue(
          ReadGalleryDirectory(repository, GalleryDirectoryCache()),
        ),
      ],
    );
    addTearDown(container.dispose);
    const sidebarKey = ValueKey('folder-tree-sidebar');

    Widget buildSidebar(
      String currentFolderPath, {
      DesktopWindowPlatform? windowPlatform,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: FolderTreeSidebar(
                key: sidebarKey,
                rootPath: rootPath,
                currentFolderPath: currentFolderPath,
                windowPlatform: windowPlatform,
                sort: GallerySort.nameAscending,
                onRefresh: () => refreshCount++,
                onChooseRootFolder: () => chooseRootCount++,
                onFolderSelected: (_) {},
                onMediaSelected: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSidebar(rootPath));
    await tester.pumpAndSettle();

    expect(find.text('Wallpapers'), findsOneWidget);
    expect(find.byTooltip(rootPath), findsOneWidget);
    expect(
      tester.getRect(find.text('Wallpapers')).top,
      greaterThanOrEqualTo(
        tester.getRect(find.byType(DesktopWindowTitleBar)).bottom,
      ),
    );

    await tester.tap(find.byTooltip('Refresh'));
    await tester.tap(find.byTooltip('Choose root folder'));

    expect(refreshCount, 1);
    expect(chooseRootCount, 1);

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, 0);

    await tester.pumpWidget(buildSidebar(targetPath));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.text('Studio Ghibli'), findsOneWidget);
    expect(find.byTooltip('Collapse folder'), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse folders'));
    await tester.pump();

    expect(find.byTooltip('Collapse folder'), findsNothing);

    await tester.pumpWidget(
      buildSidebar(rootPath, windowPlatform: DesktopWindowPlatform.windows),
    );
    await tester.pumpAndSettle();

    final windowsTitleBar = tester.getRect(find.byType(DesktopWindowTitleBar));
    final windowsRootTitle = tester.getRect(find.text('Wallpapers'));
    expect(windowsRootTitle.top, lessThan(windowsTitleBar.bottom));
    expect(windowsRootTitle.center.dy, windowsTitleBar.center.dy);
  });
}

class _FolderTreeRepository implements GalleryRepository {
  _FolderTreeRepository(this.rootPath, this.targetPath);

  final String rootPath;
  final String targetPath;

  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async {
    if (directoryPath != rootPath) return [];
    return [
      for (var index = 1; index <= 24; index++)
        GalleryFolder(
          path: '$rootPath/Folder $index',
          name: 'Folder $index',
          modifiedAt: DateTime(2026),
        ),
      GalleryFolder(
        path: targetPath,
        name: 'Studio Ghibli',
        modifiedAt: DateTime(2026),
      ),
    ];
  }

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async => [];
}
