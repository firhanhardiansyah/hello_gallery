import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../shared/models/gallery_item.dart';
import '../../shared/models/gallery_sort.dart';
import '../../shared/utils/natural_compare.dart';
import 'gallery_repository.dart';
import 'gallery_state.dart';

final galleryControllerProvider =
    NotifierProvider<GalleryController, GalleryState>(GalleryController.new);

class GalleryController extends Notifier<GalleryState> {
  @override
  GalleryState build() => const GalleryState();

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
      final items = await ref
          .read(galleryRepositoryProvider)
          .readDirectory(directoryPath);
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
