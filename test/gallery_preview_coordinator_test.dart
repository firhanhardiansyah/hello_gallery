import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hello_gallery/features/gallery/presentation/coordinators/gallery_preview_coordinator.dart';
import 'package:hello_gallery/features/gallery/presentation/states/media_preview_selection.dart';

void main() {
  test('loads and sorts preview media through injected dependencies', () async {
    MediaPreviewSelection? preview;
    final coordinator = GalleryPreviewCoordinator(
      readDirectory: (_) async => [
        _media('/gallery/b.jpg'),
        GalleryFolder(
          path: '/gallery/folder',
          name: 'folder',
          modifiedAt: _modifiedAt,
        ),
        _media('/gallery/a.jpg'),
      ],
      readSort: () => GallerySort.nameAscending,
      readPreview: () => preview,
      updatePreview: (next) => preview = next,
      isMounted: () => true,
      openPreviewRoute: (_) {},
      closePreviewRoute: () {},
      showOpenError: (error) => fail('$error'),
    );

    await coordinator.syncRoute('/gallery/b.jpg');

    expect(preview?.items.map((item) => item.name), ['a.jpg', 'b.jpg']);
    expect(preview?.initialIndex, 1);
  });

  test('delegates route changes without knowing BuildContext', () async {
    String? openedPath;
    var closeCount = 0;
    final coordinator = GalleryPreviewCoordinator(
      readDirectory: (_) async => const [],
      readSort: () => GallerySort.nameAscending,
      readPreview: () => null,
      updatePreview: (_) {},
      isMounted: () => true,
      openPreviewRoute: (path) => openedPath = path,
      closePreviewRoute: () => closeCount++,
      showOpenError: (error) => fail('$error'),
    );
    final item = _media('/gallery/image.jpg');

    coordinator.open(item);
    await coordinator.close();

    expect(openedPath, item.path);
    expect(closeCount, 1);
  });
}

final _modifiedAt = DateTime(2026);

MediaItem _media(String mediaPath) => MediaItem(
  path: mediaPath,
  name: mediaPath.split('/').last,
  modifiedAt: _modifiedAt,
  mediaType: GalleryItemType.image,
);
