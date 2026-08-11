import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/media_preview/presentation/controllers/media_preview_image_preloader.dart';
import 'package:hello_gallery/features/media_preview/presentation/states/media_preview_ui_state.dart';

void main() {
  testWidgets('precaches adjacent images but skips videos', (tester) async {
    final precachedPaths = <String>[];
    final preloader = MediaPreviewImagePreloader(
      precache: (item, _) async => precachedPaths.add(item.path),
    );
    final items = [
      _media('/gallery/previous.jpg', GalleryItemType.image),
      _media('/gallery/current.mp4', GalleryItemType.video),
      _media('/gallery/next.png', GalleryItemType.image),
      _media('/gallery/outside.jpg', GalleryItemType.image),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            preloader.schedule(
              context,
              MediaPreviewUiState(items: items, activeIndex: 1),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    expect(precachedPaths, ['/gallery/previous.jpg', '/gallery/next.png']);
    preloader.dispose();
  });

  testWidgets('does not repeat an unchanged preload window', (tester) async {
    var precacheCount = 0;
    final preloader = MediaPreviewImagePreloader(
      precache: (_, _) async => precacheCount++,
    );
    final state = MediaPreviewUiState(
      items: [_media('/gallery/image.jpg', GalleryItemType.image)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            preloader.schedule(context, state);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(precacheCount, 1);
    preloader.dispose();
  });
}

MediaItem _media(String path, GalleryItemType type) => MediaItem(
  path: path,
  name: path.split('/').last,
  modifiedAt: DateTime(2026),
  mediaType: type,
);
