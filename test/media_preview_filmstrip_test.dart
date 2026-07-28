import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/filmstrip/media_preview_filmstrip.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/filmstrip/media_preview_filmstrip_controller.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('selects media and marks the active item', (tester) async {
    final controller = MediaPreviewFilmstripController();
    addTearDown(controller.dispose);
    int? selectedIndex;

    await tester.pumpWidget(
      _FilmstripTestApp(
        controller: controller,
        items: _items,
        activeIndex: 0,
        onSelected: (index) => selectedIndex = index,
      ),
    );

    final activeSemantics = tester.widget<Semantics>(
      find.byKey(ValueKey('filmstrip-semantics:${_items.first.path}')),
    );
    expect(activeSemantics.properties.selected, isTrue);
    final thumbnail = tester.widget<Image>(
      find.descendant(
        of: find.byKey(ValueKey('filmstrip-item:${_items.first.path}')),
        matching: find.byType(Image),
      ),
    );
    expect(thumbnail.fit, BoxFit.contain);

    await tester.tap(find.byKey(ValueKey('filmstrip-item:${_items[1].path}')));

    expect(selectedIndex, 1);
  });

  testWidgets('reveals the active item in a long media list', (tester) async {
    final controller = MediaPreviewFilmstripController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _FilmstripTestApp(controller: controller, items: _items, activeIndex: 0),
    );

    controller.reveal(15, animated: false);
    await tester.pump();

    expect(controller.scrollController.offset, greaterThan(0));
  });

  testWidgets('uses vertical mouse wheel to scroll the filmstrip', (
    tester,
  ) async {
    final controller = MediaPreviewFilmstripController();
    addTearDown(controller.dispose);
    var parentScrollCount = 0;

    await tester.pumpWidget(
      _FilmstripTestApp(
        controller: controller,
        items: _items,
        activeIndex: 0,
        onParentPointerSignal: (event) {
          if (event is! PointerScrollEvent) return;
          GestureBinding.instance.pointerSignalResolver.register(
            event,
            (_) => parentScrollCount++,
          );
        },
      ),
    );

    final list = find.byKey(const ValueKey('media-preview-filmstrip-list'));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(list),
        scrollDelta: const Offset(0, 120),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    expect(controller.scrollController.offset, greaterThan(0));
    expect(parentScrollCount, 0);
  });

  testWidgets('removes thumbnail content after the hide animation', (
    tester,
  ) async {
    final controller = MediaPreviewFilmstripController();
    addTearDown(controller.dispose);
    final visibility = ValueNotifier(true);
    addTearDown(visibility.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: visibility,
        builder: (_, visible, _) => _FilmstripTestApp(
          controller: controller,
          items: _items,
          activeIndex: 0,
          visible: visible,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('media-preview-filmstrip-list')),
      findsOneWidget,
    );

    visibility.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('media-preview-filmstrip-list')),
      findsNothing,
    );
  });
}

class _FilmstripTestApp extends StatelessWidget {
  const _FilmstripTestApp({
    required this.controller,
    required this.items,
    required this.activeIndex,
    this.visible = true,
    this.onSelected,
    this.onParentPointerSignal,
  });

  final MediaPreviewFilmstripController controller;
  final List<MediaItem> items;
  final int activeIndex;
  final bool visible;
  final ValueChanged<int>? onSelected;
  final void Function(PointerSignalEvent)? onParentPointerSignal;

  @override
  Widget build(BuildContext context) => ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(
        colorTheme: AppColorTheme.indigo,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        body: Listener(
          onPointerSignal: onParentPointerSignal,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaPreviewFilmstrip(
                items: items,
                activeIndex: activeIndex,
                visible: visible,
                bottomInset: 16,
                controller: controller,
                onSelected: onSelected ?? (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final _items = List.generate(
  20,
  (index) => MediaItem(
    path: '/missing/image-$index.jpg',
    name: 'image-$index.jpg',
    modifiedAt: DateTime(2026),
    mediaType: GalleryItemType.image,
  ),
);
