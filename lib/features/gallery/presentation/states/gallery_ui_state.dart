import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';

part 'gallery_ui_state.freezed.dart';

@freezed
sealed class GalleryLoadState with _$GalleryLoadState {
  const factory GalleryLoadState.initial() = GalleryInitial;
  const factory GalleryLoadState.loading() = GalleryLoading;
  const factory GalleryLoadState.ready() = GalleryReady;
  const factory GalleryLoadState.empty() = GalleryEmpty;
  const factory GalleryLoadState.error(String message) = GalleryError;
}

@freezed
abstract class GalleryUiState with _$GalleryUiState {
  const GalleryUiState._();

  const factory GalleryUiState({
    @Default(GalleryLoadState.initial()) GalleryLoadState loadState,
    String? rootPath,
    String? currentPath,
    @Default(<GalleryItem>[]) List<GalleryItem> items,
    @Default(60) int visibleCount,
    @Default(GallerySort.nameAscending) GallerySort sort,
    @Default(false) bool canGoBack,
    @Default(false) bool canGoForward,
  }) = _GalleryUiState;

  List<GalleryItem> get visibleItems =>
      items.length <= visibleCount ? items : items.sublist(0, visibleCount);

  bool get hasMore => visibleCount < items.length;
  bool get isReady => loadState is GalleryReady;
  bool get canManageDirectory =>
      loadState is GalleryReady || loadState is GalleryEmpty;
}
