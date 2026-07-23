import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';

void main() {
  test('defaults to the initial gallery load state', () {
    const state = GalleryUiState();

    expect(state.loadState, const GalleryLoadState.initial());
    expect(state.canManageDirectory, isFalse);
    expect(state.isReady, isFalse);
  });

  test(
    'derives pagination and directory capabilities from immutable state',
    () {
      final state = GalleryUiState(
        loadState: const GalleryLoadState.ready(),
        items: [
          for (var index = 0; index < 3; index++)
            MediaItem(
              path: '/gallery/$index.jpg',
              name: '$index.jpg',
              modifiedAt: DateTime(2026),
              mediaType: GalleryItemType.image,
            ),
        ],
        visibleCount: 2,
      );

      expect(state.visibleItems.length, 2);
      expect(state.hasMore, isTrue);
      expect(state.canManageDirectory, isTrue);
      expect(state.isReady, isTrue);
      expect(() => state.items.clear(), throwsUnsupportedError);
    },
  );

  test('exposes an error message through exhaustive pattern matching', () {
    const loadState = GalleryLoadState.error('Folder unavailable');

    final message = switch (loadState) {
      GalleryError(:final message) => message,
      GalleryInitial() ||
      GalleryLoading() ||
      GalleryReady() ||
      GalleryEmpty() => null,
    };

    expect(message, 'Folder unavailable');
  });
}
