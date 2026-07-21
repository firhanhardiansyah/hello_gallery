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
    ref.read(folderPreviewJobSchedulerProvider).clear();
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
      ref.read(folderPreviewJobSchedulerProvider).clear();
      await _loadDirectory(current, forceRefresh: true);
    }
  }

  Future<void> reconcileRenamedFolder({
    required String oldPath,
    required String newPath,
  }) async {
    final current = state.currentPath;
    if (current == null) return;
    _replaceHistoryPrefix(_backHistory, oldPath, newPath);
    _replaceHistoryPrefix(_forwardHistory, oldPath, newPath);
    ref.read(readGalleryDirectoryProvider).clearCache();
    ref.read(folderPreviewJobSchedulerProvider).clear();
    await _loadDirectory(
      _replacePathPrefix(current, oldPath, newPath),
      forceRefresh: true,
    );
  }

  Future<void> reconcileTrashedFolder(String folderPath) async {
    final current = state.currentPath;
    if (current == null) return;
    final target = _isPathInside(folderPath, current)
        ? path.dirname(folderPath)
        : current;
    _backHistory.removeWhere(
      (entry) => _isPathInside(folderPath, entry) || path.equals(entry, target),
    );
    _forwardHistory.removeWhere(
      (entry) => _isPathInside(folderPath, entry) || path.equals(entry, target),
    );
    ref.read(readGalleryDirectoryProvider).clearCache();
    ref.read(folderPreviewJobSchedulerProvider).clear();
    await _loadDirectory(target, forceRefresh: true);
  }

  void _replaceHistoryPrefix(
    List<String> history,
    String oldPath,
    String newPath,
  ) {
    for (var index = 0; index < history.length; index++) {
      history[index] = _replacePathPrefix(history[index], oldPath, newPath);
    }
  }

  String _replacePathPrefix(String candidate, String oldPath, String newPath) {
    if (path.equals(candidate, oldPath)) return newPath;
    if (!path.isWithin(oldPath, candidate)) return candidate;
    return path.join(newPath, path.relative(candidate, from: oldPath));
  }

  bool _isPathInside(String ancestor, String candidate) {
    return path.equals(ancestor, candidate) ||
        path.isWithin(ancestor, candidate);
  }

  Future<void> syncDirectories(
    Set<String> directoryPaths, {
    Set<String> removedPaths = const {},
  }) async {
    final reader = ref.read(readGalleryDirectoryProvider);
    for (final directoryPath in directoryPaths) {
      reader.invalidate(directoryPath);
    }

    final current = state.currentPath;
    final root = state.rootPath;
    if (current != null && root != null) {
      String? removedAncestor;
      for (final removedPath in removedPaths) {
        if (path.equals(removedPath, current) ||
            path.isWithin(removedPath, current)) {
          removedAncestor = removedPath;
          break;
        }
      }
      if (removedAncestor != null) {
        final removedDirectory = removedAncestor;
        if (path.equals(removedDirectory, root) ||
            path.isWithin(removedDirectory, root)) {
          state = state.copyWith(
            status: GalleryStatus.error,
            items: const [],
            errorMessage: 'Root folder no longer exists',
          );
          return;
        }
        final recoveryPath = path.dirname(removedDirectory);
        _backHistory.removeWhere(
          (entry) =>
              path.equals(entry, recoveryPath) ||
              path.equals(entry, removedDirectory) ||
              path.isWithin(removedDirectory, entry),
        );
        _forwardHistory.removeWhere(
          (entry) =>
              path.equals(entry, removedDirectory) ||
              path.isWithin(removedDirectory, entry),
        );
        await _loadDirectory(recoveryPath, forceRefresh: true);
        return;
      }
    }
    if (current == null ||
        !directoryPaths.any(
          (directoryPath) => path.equals(directoryPath, current),
        )) {
      return;
    }

    final generation = ++_loadGeneration;
    try {
      final items = await reader(current, forceRefresh: true);
      if (generation != _loadGeneration) return;
      final sorted = _sortItems(items, state.sort);
      state = state.copyWith(
        status: sorted.isEmpty ? GalleryStatus.empty : GalleryStatus.ready,
        items: sorted,
        visibleCount: state.visibleCount,
      );
    } on Object {
      // A transient filesystem event can arrive before a file operation ends.
      // Keep the current snapshot; the next event or manual refresh reconciles it.
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
