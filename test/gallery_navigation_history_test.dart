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
}

class _FakeGalleryRepository implements GalleryRepository {
  int readCount = 0;

  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async {
    readCount++;
    return [];
  }

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async => [];
}
