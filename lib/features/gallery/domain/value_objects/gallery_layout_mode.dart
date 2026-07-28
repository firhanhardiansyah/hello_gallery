enum GalleryLayoutMode {
  grid,
  quilted;

  static GalleryLayoutMode fromStorage(String? value) {
    return GalleryLayoutMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => GalleryLayoutMode.grid,
    );
  }
}
