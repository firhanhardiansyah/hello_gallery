import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/input/gallery_page_input_actions.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_selection_state.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';

void main() {
  final items = [
    GalleryFolder(
      path: '/gallery/folder',
      name: 'folder',
      modifiedAt: DateTime(2026),
    ),
    MediaItem(
      path: '/gallery/image.jpg',
      name: 'image.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
    ),
  ];

  test('updates selection without accessing page state', () {
    var selection = const GallerySelectionState(folderPath: '/gallery');
    final actions = _createActions(
      gallery: GalleryUiState(items: items, visibleCount: items.length),
      readSelection: () => selection,
      updateSelection: (next) => selection = next,
    );

    actions.moveSelection(1);
    expect(selection.selectedIndex, 1);
    expect(selection.keyboardFocusVisible, isTrue);

    actions.changeSelection(1, toggle: true, extend: false);
    expect(selection.selectedPaths, {'/gallery/image.jpg'});

    actions.toggleSelectAll();
    expect(selection.selectedPaths, isEmpty);
  });

  test('chooses gallery history before navigating to the parent', () {
    var goBackCount = 0;
    var goUpCount = 0;
    final actions = _createActions(
      gallery: GalleryUiState(
        items: items,
        visibleCount: items.length,
        canGoBack: true,
      ),
      goBack: () => goBackCount++,
      goUp: () => goUpCount++,
    );

    actions.navigateBack();

    expect(goBackCount, 1);
    expect(goUpCount, 0);
  });

  test(
    'back action keeps window mode and navigates through gallery history',
    () {
      var goBackCount = 0;
      final actions = _createActions(
        gallery: GalleryUiState(
          items: items,
          visibleCount: items.length,
          canGoBack: true,
        ),
        goBack: () => goBackCount++,
      );

      actions.handleBack();

      expect(goBackCount, 1);
    },
  );

  test('history back only navigates when back history is available', () {
    var goBackCount = 0;
    final actions = _createActions(
      gallery: GalleryUiState(
        items: items,
        visibleCount: items.length,
        canGoBack: true,
      ),
      goBack: () => goBackCount++,
    );

    actions.navigateHistoryBack();
    _createActions(
      gallery: GalleryUiState(items: items, visibleCount: items.length),
      goBack: () => goBackCount++,
    ).navigateHistoryBack();

    expect(goBackCount, 1);
  });

  test('forward action only navigates when forward history is available', () {
    var goForwardCount = 0;
    final actions = _createActions(
      gallery: GalleryUiState(
        items: items,
        visibleCount: items.length,
        canGoForward: true,
      ),
      goForward: () => goForwardCount++,
    );

    actions.navigateForward();
    _createActions(
      gallery: GalleryUiState(items: items, visibleCount: items.length),
      goForward: () => goForwardCount++,
    ).navigateForward();

    expect(goForwardCount, 1);
  });

  test('opens the item at the independently supplied selection index', () {
    MediaItem? openedMedia;
    final actions = _createActions(
      gallery: GalleryUiState(items: items, visibleCount: items.length),
      readSelection: () => const GallerySelectionState(selectedIndex: 1),
      openMedia: (item) => openedMedia = item,
    );

    actions.openSelectedItem();

    expect(openedMedia?.path, '/gallery/image.jpg');
  });
}

GalleryPageInputActions _createActions({
  required GalleryUiState gallery,
  GallerySelectionState Function()? readSelection,
  void Function(GallerySelectionState)? updateSelection,
  void Function()? goBack,
  void Function()? goForward,
  void Function()? goUp,
  void Function(MediaItem)? openMedia,
}) {
  var fallbackSelection = const GallerySelectionState();
  return GalleryPageInputActions(
    readGallery: () => gallery,
    readSelection: readSelection ?? () => fallbackSelection,
    updateSelection:
        updateSelection ?? (selection) => fallbackSelection = selection,
    isPreviewActive: () => false,
    openFolder: (_) {},
    openMedia: openMedia ?? (_) {},
    goBack: goBack ?? () {},
    goForward: goForward ?? () {},
    goUp: goUp ?? () {},
  );
}
