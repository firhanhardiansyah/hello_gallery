import '../../domain/entities/gallery_item.dart';

final class GallerySelectionState {
  const GallerySelectionState({
    this.selectedIndex = 0,
    this.keyboardFocusVisible = false,
    this.selectedPaths = const {},
    this.anchorIndex,
    this.folderPath,
  });

  final int selectedIndex;
  final bool keyboardFocusVisible;
  final Set<String> selectedPaths;
  final int? anchorIndex;
  final String? folderPath;

  GallerySelectionState moveBy(int delta, List<GalleryItem> items) {
    if (items.isEmpty) return this;
    final nextIndex = (selectedIndex + delta).clamp(0, items.length - 1);
    if (nextIndex == selectedIndex && keyboardFocusVisible) return this;
    return GallerySelectionState(
      selectedIndex: nextIndex,
      keyboardFocusVisible: true,
      selectedPaths: selectedPaths,
      anchorIndex: nextIndex,
      folderPath: folderPath,
    );
  }

  GallerySelectionState select(
    int index,
    List<GalleryItem> items, {
    required bool toggle,
    required bool extend,
  }) {
    if (index < 0 || index >= items.length) return this;
    final paths = {...selectedPaths};
    if (extend && anchorIndex != null) {
      final start = anchorIndex! < index ? anchorIndex! : index;
      final end = anchorIndex! > index ? anchorIndex! : index;
      if (!toggle) paths.clear();
      paths.addAll([
        for (var itemIndex = start; itemIndex <= end; itemIndex++)
          items[itemIndex].path,
      ]);
      return GallerySelectionState(
        selectedIndex: index,
        selectedPaths: Set.unmodifiable(paths),
        anchorIndex: anchorIndex,
        folderPath: folderPath,
      );
    }

    if (toggle) {
      if (!paths.remove(items[index].path)) paths.add(items[index].path);
    } else {
      paths
        ..clear()
        ..add(items[index].path);
    }
    return GallerySelectionState(
      selectedIndex: index,
      selectedPaths: Set.unmodifiable(paths),
      anchorIndex: index,
      folderPath: folderPath,
    );
  }

  GallerySelectionState selectAll(List<GalleryItem> items) {
    if (items.isEmpty) return this;
    return GallerySelectionState(
      selectedIndex: items.length - 1,
      selectedPaths: Set.unmodifiable(items.map((item) => item.path)),
      anchorIndex: 0,
      folderPath: folderPath,
    );
  }

  GallerySelectionState clear() => GallerySelectionState(
    selectedIndex: selectedIndex,
    folderPath: folderPath,
  );

  GallerySelectionState resetForFolder(String? nextFolderPath) =>
      GallerySelectionState(folderPath: nextFolderPath);

  GallerySelectionState removePaths(Iterable<String> paths) {
    final nextPaths = {...selectedPaths}..removeAll(paths);
    return GallerySelectionState(
      selectedIndex: selectedIndex,
      selectedPaths: Set.unmodifiable(nextPaths),
      folderPath: folderPath,
    );
  }
}
