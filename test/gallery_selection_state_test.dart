import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_selection_state.dart';

void main() {
  final items = [
    for (var index = 0; index < 4; index++)
      MediaItem(
        path: '/gallery/$index.jpg',
        name: '$index.jpg',
        modifiedAt: DateTime(2026),
        mediaType: GalleryItemType.image,
      ),
  ];

  test('extends selection from the current anchor', () {
    final anchored = const GallerySelectionState().select(
      1,
      items,
      toggle: false,
      extend: false,
    );
    final extended = anchored.select(3, items, toggle: false, extend: true);

    expect(extended.selectedPaths, {
      '/gallery/1.jpg',
      '/gallery/2.jpg',
      '/gallery/3.jpg',
    });
    expect(extended.anchorIndex, 1);
  });

  test('resets all transient selection state for a new folder', () {
    final selected = GallerySelectionState(
      selectedIndex: 3,
      keyboardFocusVisible: true,
      selectedPaths: const {'/gallery/3.jpg'},
      anchorIndex: 3,
      folderPath: '/gallery',
    );

    final reset = selected.resetForFolder('/gallery/next');

    expect(reset.selectedIndex, 0);
    expect(reset.keyboardFocusVisible, isFalse);
    expect(reset.selectedPaths, isEmpty);
    expect(reset.anchorIndex, isNull);
    expect(reset.folderPath, '/gallery/next');
  });
}
