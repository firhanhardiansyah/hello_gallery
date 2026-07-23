import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_body.dart';

void main() {
  testWidgets('restores an independent scroll position for each folder', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_gallery(controller, path: '/gallery'));
    await tester.pump();
    controller.jumpTo(720);
    await tester.pump();

    await tester.pumpWidget(_gallery(controller, path: '/gallery/child'));
    await tester.pump();
    expect(controller.offset, 0);
    controller.jumpTo(360);
    await tester.pump();

    await tester.pumpWidget(_gallery(controller, path: '/gallery'));
    await tester.pump();
    expect(controller.offset, 720);

    await tester.pumpWidget(_gallery(controller, path: '/gallery/child'));
    await tester.pump();
    expect(controller.offset, 360);
  });

  testWidgets('restores scroll after the gallery is replaced by preview', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_gallery(controller, path: '/gallery'));
    await tester.pump();
    controller.jumpTo(640);
    await tester.pump();

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SizedBox.expand())),
    );
    await tester.pump();

    await tester.pumpWidget(_gallery(controller, path: '/gallery'));
    await tester.pump();
    expect(controller.offset, 640);
  });
}

Widget _gallery(ScrollController controller, {required String path}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: GalleryBody(
          state: GalleryUiState(
            loadState: const GalleryLoadState.ready(),
            rootPath: '/gallery',
            currentPath: path,
            items: [
              for (var index = 0; index < 80; index++)
                MediaItem(
                  path: '$path/image-$index.jpg',
                  name: 'image-$index.jpg',
                  modifiedAt: DateTime(2026),
                  mediaType: GalleryItemType.image,
                ),
            ],
          ),
          scrollController: controller,
          selectedIndex: 0,
          selectedPaths: const {},
          onSelectionChanged: (_, {required toggle, required extend}) {},
          onClearSelection: () {},
          onColumnCountChanged: (_) {},
          onFolderSelected: (_) {},
          onMediaSelected: (_) {},
          onMediaDropped: (_, _) {},
        ),
      ),
    ),
  );
}
