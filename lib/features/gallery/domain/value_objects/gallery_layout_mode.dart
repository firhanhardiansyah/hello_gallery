enum GalleryLayoutMode {
  grid,
  quilted,
  masonry;

  static GalleryLayoutMode fromStorage(String? value) {
    return GalleryLayoutMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => GalleryLayoutMode.grid,
    );
  }
}
