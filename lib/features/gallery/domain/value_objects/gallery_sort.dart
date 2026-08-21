enum GallerySort {
  nameAscending,
  nameDescending,
  newest,
  oldest;

  static GallerySort fromStorage(String? value) {
    for (final sort in GallerySort.values) {
      if (sort.name == value) return sort;
    }
    return GallerySort.nameAscending;
  }
}

extension GallerySortLabel on GallerySort {
  String get label => switch (this) {
    GallerySort.nameAscending => 'A–Z',
    GallerySort.nameDescending => 'Z–A',
    GallerySort.newest => 'Newest',
    GallerySort.oldest => 'Oldest',
  };
}
