import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_layout_mode.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_card.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_body.dart';
import 'package:hello_gallery/features/thumbnail/application/providers/media_dimensions_dependencies.dart';

void main() {
  testWidgets('quilted layout mixes large and small gallery tiles', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GalleryBody(
              state: GalleryUiState(
                loadState: const GalleryLoadState.ready(),
                currentPath: '/gallery',
                items: [
                  for (var index = 0; index < 8; index++)
                    MediaItem(
                      path: '/gallery/image-$index.jpg',
                      name: 'image-$index.jpg',
                      modifiedAt: DateTime(2026),
                      mediaType: GalleryItemType.image,
                    ),
                ],
              ),
              layoutMode: GalleryLayoutMode.quilted,
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
      ),
    );
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.gridDelegate, isA<SliverQuiltedGridDelegate>());

    final largeTile = tester.getRect(find.byType(GalleryCard).at(0));
    final smallTile = tester.getRect(find.byType(GalleryCard).at(1));
    expect(largeTile.width, greaterThan(smallTile.width));
    expect(largeTile.height, greaterThan(smallTile.height));
  });

  testWidgets('masonry layout preserves each media aspect ratio', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaAspectRatioProvider.overrideWith(
            (ref, item) async => item.name.startsWith('landscape') ? 2 : 0.5,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GalleryBody(
              state: GalleryUiState(
                loadState: const GalleryLoadState.ready(),
                currentPath: '/gallery',
                items: [
                  MediaItem(
                    path: '/gallery/landscape.jpg',
                    name: 'landscape.jpg',
                    modifiedAt: DateTime(2026),
                    mediaType: GalleryItemType.image,
                  ),
                  MediaItem(
                    path: '/gallery/portrait.jpg',
                    name: 'portrait.jpg',
                    modifiedAt: DateTime(2026),
                    mediaType: GalleryItemType.image,
                  ),
                ],
              ),
              layoutMode: GalleryLayoutMode.masonry,
              showItemNames: false,
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
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MasonryGridView), findsOneWidget);
    final landscape = tester.getRect(find.byType(GalleryCard).at(0));
    final portrait = tester.getRect(find.byType(GalleryCard).at(1));
    expect(landscape.width / landscape.height, closeTo(2, 0.01));
    expect(portrait.width / portrait.height, closeTo(0.5, 0.01));
  });
}
