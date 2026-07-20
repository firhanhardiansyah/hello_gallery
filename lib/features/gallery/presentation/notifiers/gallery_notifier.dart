import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hello_gallery/core/utils/natural_compare.dart';
import '../../application/providers/gallery_dependencies.dart';
import '../states/gallery_ui_state.dart';

final galleryNotifierProvider =
    NotifierProvider<GalleryNotifier, GalleryUiState>(GalleryNotifier.new);

class GalleryNotifier extends Notifier<GalleryUiState> {
  @override
  GalleryUiState build() => const GalleryUiState();

  Future<void> setRoot(String rootPath) async {
    state = state.copyWith(rootPath: rootPath);
    await openDirectory(rootPath);
  }

  Future<void> openDirectory(String directoryPath) async {
    state = state.copyWith(
      status: GalleryStatus.loading,
      currentPath: directoryPath,
      visibleCount: 60,
    );
    try {
      final items = await ref.read(readGalleryDirectoryProvider)(directoryPath);
      final sorted = _sortItems(items, state.sort);
      state = state.copyWith(
        status: sorted.isEmpty ? GalleryStatus.empty : GalleryStatus.ready,
        items: sorted,
        visibleCount: 60,
      );
    } catch (error) {
      state = state.copyWith(
        status: GalleryStatus.error,
        items: const [],
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> goUp() async {
    final root = state.rootPath;
    final current = state.currentPath;
    if (root == null || current == null || path.equals(root, current)) return;
    final parent = path.dirname(current);
    if (path.isWithin(root, parent) || path.equals(root, parent)) {
      await openDirectory(parent);
    }
  }

  void loadMore() {
    if (!state.hasMore) return;
    state = state.copyWith(visibleCount: state.visibleCount + 60);
  }

  void setSort(GallerySort sort) {
    state = state.copyWith(sort: sort, items: _sortItems(state.items, sort));
  }

  List<GalleryItem> _sortItems(List<GalleryItem> input, GallerySort sort) {
    final items = [...input];
    items.sort((a, b) {
      final folderOrder = (a is GalleryFolder ? 0 : 1).compareTo(
        b is GalleryFolder ? 0 : 1,
      );
      if (folderOrder != 0) return folderOrder;
      return switch (sort) {
        GallerySort.nameAscending => naturalCompare(a.name, b.name),
        GallerySort.nameDescending => naturalCompare(b.name, a.name),
        GallerySort.newest => b.modifiedAt.compareTo(a.modifiedAt),
        GallerySort.oldest => a.modifiedAt.compareTo(b.modifiedAt),
      };
    });
    return items;
  }
}
