import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/providers/gallery_dependencies.dart';
import 'package:hello_gallery/features/gallery/application/services/gallery_directory_cache.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/read_gallery_directory.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:hello_gallery/features/gallery/presentation/notifiers/gallery_notifier.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';

void main() {
  late ProviderContainer container;
  late _FakeGalleryRepository repository;

  setUp(() {
    repository = _FakeGalleryRepository();
    container = ProviderContainer(
      overrides: [
        readGalleryDirectoryProvider.overrideWithValue(
          ReadGalleryDirectory(repository, GalleryDirectoryCache()),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('navigates backward and forward through folder history', () async {
    final notifier = container.read(galleryNotifierProvider.notifier);

    await notifier.setRoot('/gallery');
    await notifier.openDirectory('/gallery/wallpapers');

    expect(container.read(galleryNotifierProvider).canGoBack, isTrue);
    expect(container.read(galleryNotifierProvider).canGoForward, isFalse);
    expect(repository.readCount, 2);

    final backNavigation = notifier.goBack();

    expect(container.read(galleryNotifierProvider).status, GalleryStatus.empty);
    await backNavigation;

    expect(container.read(galleryNotifierProvider).currentPath, '/gallery');
    expect(container.read(galleryNotifierProvider).canGoBack, isFalse);
    expect(container.read(galleryNotifierProvider).canGoForward, isTrue);

    await notifier.goForward();

    expect(
      container.read(galleryNotifierProvider).currentPath,
      '/gallery/wallpapers',
    );
    expect(container.read(galleryNotifierProvider).canGoBack, isTrue);
    expect(container.read(galleryNotifierProvider).canGoForward, isFalse);
    expect(repository.readCount, 2);
  });

  test('refresh does not add a navigation history entry', () async {
    final notifier = container.read(galleryNotifierProvider.notifier);

    await notifier.setRoot('/gallery');
    await notifier.refresh();

    expect(container.read(galleryNotifierProvider).canGoBack, isFalse);
    expect(container.read(galleryNotifierProvider).canGoForward, isFalse);
    expect(repository.readCount, 2);
  });

  test('auto sync silently reloads only the active affected folder', () async {
    final notifier = container.read(galleryNotifierProvider.notifier);
    repository.items = [
      MediaItem(
        path: '/gallery/old.jpg',
        name: 'old.jpg',
        modifiedAt: DateTime(2026),
        mediaType: GalleryItemType.image,
      ),
    ];
    await notifier.setRoot('/gallery');
    repository.items = [
      MediaItem(
        path: '/gallery/new.jpg',
        name: 'new.jpg',
        modifiedAt: DateTime(2026),
        mediaType: GalleryItemType.image,
      ),
    ];

    await notifier.syncDirectories({'/gallery/other'});
    expect(repository.readCount, 1);

    await notifier.syncDirectories({'/gallery'});

    final state = container.read(galleryNotifierProvider);
    expect(repository.readCount, 2);
    expect(state.status, GalleryStatus.ready);
    expect(state.items.single.name, 'new.jpg');
    expect(state.canGoBack, isFalse);
  });

  test(
    'auto sync returns to parent when the active folder is removed',
    () async {
      final notifier = container.read(galleryNotifierProvider.notifier);
      await notifier.setRoot('/gallery');
      await notifier.openDirectory('/gallery/Anime');

      await notifier.syncDirectories(
        {'/gallery'},
        removedPaths: {'/gallery/Anime'},
      );

      final state = container.read(galleryNotifierProvider);
      expect(state.currentPath, '/gallery');
      expect(state.canGoBack, isFalse);
      expect(state.status, GalleryStatus.empty);
    },
  );
}

class _FakeGalleryRepository implements GalleryRepository {
  int readCount = 0;
  List<GalleryItem> items = const [];

  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async {
    readCount++;
    return items;
  }

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async => [];
}
