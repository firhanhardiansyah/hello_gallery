import '../../shared/models/gallery_item.dart';
import '../../shared/models/gallery_sort.dart';

enum GalleryStatus { initial, loading, ready, empty, error }

class GalleryState {
  const GalleryState({
    this.status = GalleryStatus.initial,
    this.rootPath,
    this.currentPath,
    this.items = const [],
    this.visibleCount = 60,
    this.sort = GallerySort.nameAscending,
    this.errorMessage,
  });

  final GalleryStatus status;
  final String? rootPath;
  final String? currentPath;
  final List<GalleryItem> items;
  final int visibleCount;
  final GallerySort sort;
  final String? errorMessage;

  List<GalleryItem> get visibleItems => items.take(visibleCount).toList();
  bool get hasMore => visibleCount < items.length;

  GalleryState copyWith({
    GalleryStatus? status,
    String? rootPath,
    String? currentPath,
    List<GalleryItem>? items,
    int? visibleCount,
    GallerySort? sort,
    String? errorMessage,
  }) => GalleryState(
    status: status ?? this.status,
    rootPath: rootPath ?? this.rootPath,
    currentPath: currentPath ?? this.currentPath,
    items: items ?? this.items,
    visibleCount: visibleCount ?? this.visibleCount,
    sort: sort ?? this.sort,
    errorMessage: errorMessage,
  );
}
