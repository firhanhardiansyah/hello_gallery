import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';

enum GalleryStatus { initial, loading, ready, empty, error }

class GalleryUiState {
  const GalleryUiState({
    this.status = GalleryStatus.initial,
    this.rootPath,
    this.currentPath,
    this.items = const [],
    this.visibleCount = 60,
    this.sort = GallerySort.nameAscending,
    this.errorMessage,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  final GalleryStatus status;
  final String? rootPath;
  final String? currentPath;
  final List<GalleryItem> items;
  final int visibleCount;
  final GallerySort sort;
  final String? errorMessage;
  final bool canGoBack;
  final bool canGoForward;

  List<GalleryItem> get visibleItems =>
      items.length <= visibleCount ? items : items.sublist(0, visibleCount);
  bool get hasMore => visibleCount < items.length;

  GalleryUiState copyWith({
    GalleryStatus? status,
    String? rootPath,
    String? currentPath,
    List<GalleryItem>? items,
    int? visibleCount,
    GallerySort? sort,
    String? errorMessage,
    bool? canGoBack,
    bool? canGoForward,
  }) => GalleryUiState(
    status: status ?? this.status,
    rootPath: rootPath ?? this.rootPath,
    currentPath: currentPath ?? this.currentPath,
    items: items ?? this.items,
    visibleCount: visibleCount ?? this.visibleCount,
    sort: sort ?? this.sort,
    errorMessage: errorMessage,
    canGoBack: canGoBack ?? this.canGoBack,
    canGoForward: canGoForward ?? this.canGoForward,
  );
}
