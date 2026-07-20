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

  GalleryUiState copyWith({
    GalleryStatus? status,
    String? rootPath,
    String? currentPath,
    List<GalleryItem>? items,
    int? visibleCount,
    GallerySort? sort,
    String? errorMessage,
  }) => GalleryUiState(
    status: status ?? this.status,
    rootPath: rootPath ?? this.rootPath,
    currentPath: currentPath ?? this.currentPath,
    items: items ?? this.items,
    visibleCount: visibleCount ?? this.visibleCount,
    sort: sort ?? this.sort,
    errorMessage: errorMessage,
  );
}
