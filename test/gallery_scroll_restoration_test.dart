import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_layout_mode.dart';
import 'package:hello_gallery/features/gallery/presentation/coordinators/gallery_scroll_restorer.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_body.dart';
import 'package:hello_gallery/features/thumbnail/application/providers/media_dimensions_dependencies.dart';

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

    await tester.pumpWidget(_previewPlaceholder());
    await tester.pump();

    await tester.pumpWidget(_gallery(controller, path: '/gallery'));
    await tester.pump();
    expect(controller.offset, 640);
  });

  testWidgets('restores masonry scroll after returning from preview', (
    tester,
  ) async {
    final controller = ScrollController();
    var previewActive = false;
    var mounted = true;
    final restorer = GalleryScrollRestorer(
      scrollController: controller,
      isMounted: () => mounted,
      isPreviewActive: () => previewActive,
    );
    addTearDown(() {
      mounted = false;
      restorer.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      _gallery(
        controller,
        path: '/gallery',
        layoutMode: GalleryLayoutMode.masonry,
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(640);
    await tester.pump();

    restorer.captureBeforePreview();
    previewActive = true;
    await tester.pumpWidget(_previewPlaceholder());
    await tester.pump();

    previewActive = false;
    restorer.restoreAfterPreview();
    await tester.pumpWidget(
      _gallery(
        controller,
        path: '/gallery',
        layoutMode: GalleryLayoutMode.masonry,
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 640);
  });
}

Widget _previewPlaceholder() {
  return ProviderScope(
    overrides: [
      mediaAspectRatioProvider.overrideWith(
        (ref, item) async => item.name.hashCode.isEven ? 2 : 0.6,
      ),
    ],
    child: const MaterialApp(home: SizedBox.expand()),
  );
}

Widget _gallery(
  ScrollController controller, {
  required String path,
  GalleryLayoutMode layoutMode = GalleryLayoutMode.grid,
}) {
  return ProviderScope(
    overrides: [
      mediaAspectRatioProvider.overrideWith(
        (ref, item) async => item.name.hashCode.isEven ? 2 : 0.6,
      ),
    ],
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
          layoutMode: layoutMode,
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
