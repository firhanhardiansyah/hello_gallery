enum GallerySort { nameAscending, nameDescending, newest, oldest }

extension GallerySortLabel on GallerySort {
  String get label => switch (this) {
    GallerySort.nameAscending => 'A–Z',
    GallerySort.nameDescending => 'Z–A',
    GallerySort.newest => 'Newest',
    GallerySort.oldest => 'Oldest',
  };
}
