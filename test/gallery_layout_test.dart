import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_layout_mode.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_card.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_body.dart';

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
}
