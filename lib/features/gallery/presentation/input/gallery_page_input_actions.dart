import 'dart:async';

import '../states/gallery_selection_state.dart';
import '../../domain/entities/gallery_item.dart';
import '../states/gallery_ui_state.dart';

typedef GallerySelectionReader = GallerySelectionState Function();
typedef GallerySelectionUpdater =
    void Function(GallerySelectionState selection);

final class GalleryPageInputActions {
  const GalleryPageInputActions({
    required this.readGallery,
    required this.readSelection,
    required this.updateSelection,
    required this.isPreviewActive,
    required this.openFolder,
    required this.openMedia,
    required this.goBack,
    required this.goUp,
  });

  final GalleryUiState Function() readGallery;
  final GallerySelectionReader readSelection;
  final GallerySelectionUpdater updateSelection;
  final bool Function() isPreviewActive;
  final FutureOr<void> Function(String folderPath) openFolder;
  final FutureOr<void> Function(MediaItem item) openMedia;
  final FutureOr<void> Function() goBack;
  final FutureOr<void> Function() goUp;

  void handleBack() {
    if (!isPreviewActive() && readSelection().selectedPaths.isNotEmpty) {
      clearSelection();
    } else {
      navigateBack();
    }
  }

  void handleGamepadBack() {
    if (readSelection().selectedPaths.isNotEmpty) {
      clearSelection();
      return;
    }
    navigateBack();
  }

  void navigateBack() {
    final gallery = readGallery();
    unawaited(Future.sync(gallery.canGoBack ? goBack : goUp));
  }

  void moveSelection(int delta) {
    final next = readSelection().moveBy(delta, readGallery().visibleItems);
    _updateIfChanged(next);
  }

  void changeSelection(
    int index, {
    required bool toggle,
    required bool extend,
  }) {
    final next = readSelection().select(
      index,
      readGallery().visibleItems,
      toggle: toggle,
      extend: extend,
    );
    _updateIfChanged(next);
  }

  void clearSelection() {
    final selection = readSelection();
    if (selection.selectedPaths.isEmpty && !selection.keyboardFocusVisible) {
      return;
    }
    updateSelection(selection.clear());
  }

  void selectAll() {
    final next = readSelection().selectAll(readGallery().visibleItems);
    _updateIfChanged(next);
  }

  void toggleSelectAll() {
    if (readSelection().selectedPaths.isEmpty) {
      selectAll();
    } else {
      clearSelection();
    }
  }

  void openSelectedItem() {
    final gallery = readGallery();
    if (gallery.visibleItems.isEmpty) return;
    final selection = readSelection();
    final index = selection.selectedIndex.clamp(
      0,
      gallery.visibleItems.length - 1,
    );
    final item = gallery.visibleItems[index];
    if (item is GalleryFolder) {
      unawaited(Future.sync(() => openFolder(item.path)));
    } else if (item is MediaItem) {
      unawaited(Future.sync(() => openMedia(item)));
    }
  }

  void _updateIfChanged(GallerySelectionState next) {
    if (!identical(next, readSelection())) updateSelection(next);
  }
}
