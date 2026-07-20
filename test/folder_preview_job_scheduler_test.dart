import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/providers/gallery_dependencies.dart';
import 'package:hello_gallery/features/gallery/application/services/folder_preview_cache.dart';
import 'package:hello_gallery/features/gallery/application/services/folder_preview_job_scheduler.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/find_folder_preview_media.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/gallery_repository.dart';

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
}

final class _PreviewRepository implements GalleryRepository {
  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async => [
    MediaItem(
      path: '$directoryPath/preview.jpg',
      name: 'preview.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
    ),
  ];

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async =>
      const [];
}
