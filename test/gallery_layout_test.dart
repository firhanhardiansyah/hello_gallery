import 'dart:async';

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
  testWidgets('uses a top progress line while every gallery layout loads', (
    tester,
  ) async {
    for (final layoutMode in GalleryLayoutMode.values) {
      final controller = ScrollController();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GalleryBody(
                key: ValueKey('loading-${layoutMode.name}'),
                state: const GalleryUiState(
                  loadState: GalleryLoadState.loading(),
                ),
                layoutMode: layoutMode,
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
      await tester.pump(const Duration(milliseconds: 240));

      expect(
        find.byKey(const ValueKey('gallery-loading-progress')),
        findsOneWidget,
      );
      expect(find.byType(GalleryCard), findsNothing);
      controller.dispose();
    }
  });

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

  testWidgets('keeps frame padding while applying item spacing', (
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
                  MediaItem(
                    path: '/gallery/image.jpg',
                    name: 'image.jpg',
                    modifiedAt: DateTime(2026),
                    mediaType: GalleryItemType.image,
                  ),
                ],
              ),
              gridSpacing: 12,
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
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
    expect(grid.padding, const EdgeInsets.all(12));
    expect(delegate.mainAxisSpacing, 12);
    expect(delegate.crossAxisSpacing, 12);
  });

  testWidgets(
    'aspect ratio grid keeps square cells and contains media thumbnails',
    (tester) async {
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
                    MediaItem(
                      path: '/gallery/landscape.jpg',
                      name: 'landscape.jpg',
                      modifiedAt: DateTime(2026),
                      mediaType: GalleryItemType.image,
                    ),
                  ],
                ),
                layoutMode: GalleryLayoutMode.aspectRatioGrid,
                showItemNames: false,
                cardCornerRadius: 16,
                scrollController: controller,
                selectedIndex: 0,
                selectedPaths: const {'/gallery/landscape.jpg'},
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

      final card = tester.getRect(find.byType(GalleryCard));
      final thumbnail = tester.widget<Image>(
        find.descendant(
          of: find.byType(GalleryCard),
          matching: find.byType(Image),
        ),
      );
      expect(card.width / card.height, closeTo(1, 0.01));
      expect(thumbnail.fit, BoxFit.contain);
      final thumbnailClip = tester.widget<ClipRRect>(
        find.byKey(const ValueKey('aspect-ratio-thumbnail-clip')),
      );
      expect(thumbnailClip.borderRadius, BorderRadius.circular(16));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aspect-ratio-thumbnail-frame')),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
      final selectionDecoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byKey(
                        const ValueKey('gallery-card-selection-border'),
                      ),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(selectionDecoration.color, isNull);
    },
  );

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
    expect(landscape.width, closeTo(portrait.width, 0.01));
    expect(landscape.width / landscape.height, closeTo(4 / 3, 0.01));
    expect(portrait.width / portrait.height, closeTo(0.5, 0.01));
  });

  testWidgets('defers masonry ratio changes while scrolling', (tester) async {
    final ratio = Completer<double>();
    final item = MediaItem(
      path: '/gallery/landscape.jpg',
      name: 'landscape.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
    );

    Widget card({required bool deferAspectRatioUpdates}) => ProviderScope(
      overrides: [
        mediaAspectRatioProvider.overrideWith((ref, item) => ratio.future),
      ],
      child: MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            child: GalleryCard(
              key: const ValueKey('stable-masonry-card'),
              item: item,
              showItemName: false,
              useOriginalAspectRatio: true,
              deferAspectRatioUpdates: deferAspectRatioUpdates,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(card(deferAspectRatioUpdates: true));
    await tester.pump();
    final preview = find.byKey(const ValueKey('gallery-card-preview'));
    final initial = tester.getRect(preview);
    expect(initial.width / initial.height, closeTo(0.75, 0.01));

    ratio.complete(2);
    await tester.pump();
    final whileScrolling = tester.getRect(preview);
    expect(whileScrolling, initial);

    await tester.pumpWidget(card(deferAspectRatioUpdates: false));
    await tester.pump();
    final afterScroll = tester.getRect(preview);
    expect(afterScroll.width / afterScroll.height, closeTo(4 / 3, 0.01));
  });

  testWidgets('waits for initial masonry ratios before showing cards', (
    tester,
  ) async {
    final ratio = Completer<double>();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final item = MediaItem(
      path: '/gallery/landscape.jpg',
      name: 'landscape.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaAspectRatioProvider.overrideWith((ref, item) => ratio.future),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GalleryBody(
              state: GalleryUiState(
                loadState: const GalleryLoadState.ready(),
                currentPath: '/gallery',
                items: [item],
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
    await tester.pump(const Duration(milliseconds: 240));

    expect(find.byType(MasonryGridView), findsNothing);
    expect(
      find.byKey(const ValueKey('gallery-loading-progress')),
      findsOneWidget,
    );

    ratio.complete(2);
    await tester.pump();
    await tester.pump();

    expect(find.byType(MasonryGridView), findsOneWidget);
    final card = tester.getRect(find.byType(GalleryCard));
    expect(card.width / card.height, closeTo(4 / 3, 0.01));
  });
}
