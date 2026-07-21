import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/gallery/application/providers/gallery_dependencies.dart';
import 'package:hello_gallery/features/gallery/application/services/folder_preview_cache.dart';
import 'package:hello_gallery/features/gallery/application/services/folder_preview_job_scheduler.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/find_folder_preview_media.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_body.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('retries a visible folder preview after queue eviction', (
    tester,
  ) async {
    final repository = _PreviewRepository();
    final scheduler = FolderPreviewJobScheduler(
      FindFolderPreviewMedia(repository),
      FolderPreviewCache(),
    )..setScrolling(true);
    final container = ProviderContainer(
      overrides: [
        folderPreviewJobSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);

    final folders = [
      for (var index = 0; index < 25; index++)
        GalleryFolder(
          path: '/gallery/folder-$index',
          name: 'folder-$index',
          modifiedAt: DateTime(2026),
        ),
    ];
    final subscriptions = [
      for (final folder in folders)
        container.listen(folderPreviewProvider(folder), (_, _) {}),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });

    await tester.pump(const Duration(milliseconds: 130));
    scheduler.setScrolling(false);
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final firstPreview = container.read(folderPreviewProvider(folders.first));
    expect(firstPreview.hasValue, isTrue);
    expect(firstPreview.requireValue.single.name, 'preview.jpg');
  });

  testWidgets('resumes folder previews when gallery navigation changes', (
    tester,
  ) async {
    final repository = _PreviewRepository();
    final scheduler = FolderPreviewJobScheduler(
      FindFolderPreviewMedia(repository),
      FolderPreviewCache(),
    );
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    Widget buildGallery(GalleryUiState state) => ProviderScope(
      overrides: [
        folderPreviewJobSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.light,
        ),
        home: GalleryBody(
          state: state,
          scrollController: scrollController,
          selectedIndex: 0,
          selectedPaths: const {},
          onSelectionChanged:
              (_, {required bool toggle, required bool extend}) {},
          onClearSelection: () {},
          onColumnCountChanged: (_) {},
          onFolderSelected: (_) {},
          onMediaSelected: (_) {},
          onMediaDropped: (_, _) {},
        ),
      ),
    );

    await tester.pumpWidget(
      buildGallery(
        const GalleryUiState(
          status: GalleryStatus.ready,
          currentPath: '/gallery/first',
        ),
      ),
    );
    scheduler.setScrolling(true);

    final folder = GalleryFolder(
      path: '/gallery/second/album',
      name: 'album',
      modifiedAt: DateTime(2026),
    );
    await tester.pumpWidget(
      buildGallery(
        GalleryUiState(
          status: GalleryStatus.ready,
          currentPath: '/gallery/second',
          items: [folder],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(repository.readPaths, contains(folder.path));
  });

  testWidgets('does not persist an empty folder preview in cache', (
    tester,
  ) async {
    final repository = _EmptyPreviewRepository();
    final scheduler = FolderPreviewJobScheduler(
      FindFolderPreviewMedia(repository),
      FolderPreviewCache(),
    );
    final folder = GalleryFolder(
      path: '/gallery/empty',
      name: 'empty',
      modifiedAt: DateTime(2026),
    );

    final first = scheduler.getPreview(folder);
    await tester.pump();
    expect(await first.result, isEmpty);
    final second = scheduler.getPreview(folder);
    await tester.pump();
    expect(await second.result, isEmpty);

    expect(repository.readCount, 2);
  });
}

final class _PreviewRepository implements GalleryRepository {
  final readPaths = <String>[];

  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async {
    readPaths.add(directoryPath);
    return [
      MediaItem(
        path: '$directoryPath/preview.jpg',
        name: 'preview.jpg',
        modifiedAt: DateTime(2026),
        mediaType: GalleryItemType.image,
      ),
    ];
  }

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async =>
      const [];
}

final class _EmptyPreviewRepository implements GalleryRepository {
  var readCount = 0;

  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async {
    readCount++;
    return const [];
  }

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async =>
      const [];
}
