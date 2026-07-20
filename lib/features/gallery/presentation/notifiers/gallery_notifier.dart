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
  final _backHistory = <String>[];
  final _forwardHistory = <String>[];
  int _loadGeneration = 0;

  @override
  GalleryUiState build() => const GalleryUiState();

  Future<void> setRoot(String rootPath) async {
    _backHistory.clear();
    _forwardHistory.clear();
    state = GalleryUiState(rootPath: rootPath, sort: state.sort);
    await _loadDirectory(rootPath);
  }

  Future<void> openDirectory(String directoryPath) async {
    final current = state.currentPath;
    if (current != null && !path.equals(current, directoryPath)) {
      _backHistory.add(current);
      _forwardHistory.clear();
    }
    await _loadDirectory(directoryPath);
  }

  Future<void> goBack() async {
    if (_backHistory.isEmpty) return;
    final current = state.currentPath;
    final target = _backHistory.removeLast();
    if (current != null) _forwardHistory.add(current);
    await _loadDirectory(target);
  }

  Future<void> goForward() async {
    if (_forwardHistory.isEmpty) return;
    final current = state.currentPath;
    final target = _forwardHistory.removeLast();
    if (current != null) _backHistory.add(current);
    await _loadDirectory(target);
  }

  Future<void> _loadDirectory(
    String directoryPath, {
    bool forceRefresh = false,
  }) async {
    final generation = ++_loadGeneration;
    final reader = ref.read(readGalleryDirectoryProvider);
    final cached = forceRefresh ? null : reader.getCached(directoryPath);
    if (cached != null) {
      _showDirectory(directoryPath, cached);
      return;
    }

    state = state.copyWith(
      status: GalleryStatus.loading,
      currentPath: directoryPath,
      visibleCount: 60,
      canGoBack: _backHistory.isNotEmpty,
      canGoForward: _forwardHistory.isNotEmpty,
    );
    try {
      final items = await reader(directoryPath, forceRefresh: forceRefresh);
      if (generation != _loadGeneration) return;
      _showDirectory(directoryPath, items);
    } catch (error) {
      if (generation != _loadGeneration) return;
      state = state.copyWith(
        status: GalleryStatus.error,
        items: const [],
        errorMessage: error.toString(),
      );
    }
  }

  void _showDirectory(String directoryPath, List<GalleryItem> items) {
    final sorted = _sortItems(items, state.sort);
    state = state.copyWith(
      status: sorted.isEmpty ? GalleryStatus.empty : GalleryStatus.ready,
      currentPath: directoryPath,
      items: sorted,
      visibleCount: 60,
      canGoBack: _backHistory.isNotEmpty,
      canGoForward: _forwardHistory.isNotEmpty,
    );
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

  Future<void> refresh() async {
    final current = state.currentPath;
    if (current != null) {
      await _loadDirectory(current, forceRefresh: true);
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
