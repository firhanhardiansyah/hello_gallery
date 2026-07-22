import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_card.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_body.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('opens on tap and selects with desktop modifier or long press', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final selections = <({int index, bool toggle, bool extend})>[];
    MediaItem? openedMedia;
    final first = _media('/gallery/one.jpg');
    final second = _media('/gallery/two.jpg');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: GalleryBody(
              state: GalleryUiState(
                status: GalleryStatus.ready,
                currentPath: '/gallery',
                items: [first, second],
              ),
              scrollController: controller,
              selectedIndex: 0,
              selectedPaths: const {},
              onSelectionChanged: (index, {required toggle, required extend}) =>
                  selections.add((
                    index: index,
                    toggle: toggle,
                    extend: extend,
                  )),
              onClearSelection: () {},
              onColumnCountChanged: (_) {},
              onFolderSelected: (_) {},
              onMediaSelected: (media) => openedMedia = media,
              onMediaDropped: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstCard = tester.getRect(find.byType(GalleryCard).at(0));
    final secondCard = tester.getRect(find.byType(GalleryCard).at(1));
    expect(firstCard.width / firstCard.height, closeTo(3 / 4, 0.01));
    expect(secondCard.left - firstCard.right, AppSpacing.sm);

    await tester.tap(find.text('one.jpg'));
    expect(selections, isEmpty);
    expect(openedMedia, first);

    openedMedia = null;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text('two.jpg'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(selections.last, (index: 1, toggle: true, extend: false));
    expect(openedMedia, isNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('one.jpg'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(selections.last, (index: 0, toggle: false, extend: true));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('two.jpg')),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selections.last, (index: 1, toggle: false, extend: false));
  });

  testWidgets('tap toggles items while selection mode is active', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final selections = <({int index, bool toggle, bool extend})>[];
    MediaItem? openedMedia;
    final first = _media('/gallery/one.jpg');
    final second = _media('/gallery/two.jpg');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: GalleryBody(
              state: GalleryUiState(
                status: GalleryStatus.ready,
                currentPath: '/gallery',
                items: [first, second],
              ),
              scrollController: controller,
              selectedIndex: 0,
              selectedPaths: {first.path},
              onSelectionChanged: (index, {required toggle, required extend}) =>
                  selections.add((
                    index: index,
                    toggle: toggle,
                    extend: extend,
                  )),
              onClearSelection: () {},
              onColumnCountChanged: (_) {},
              onFolderSelected: (_) {},
              onMediaSelected: (media) => openedMedia = media,
              onMediaDropped: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('two.jpg'));

    expect(selections.single, (index: 1, toggle: true, extend: false));
    expect(openedMedia, isNull);
  });
}

MediaItem _media(String path) => MediaItem(
  path: path,
  name: path.split('/').last,
  modifiedAt: DateTime(2026),
  mediaType: GalleryItemType.image,
);
