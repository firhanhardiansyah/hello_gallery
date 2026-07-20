import 'package:hello_gallery/core/utils/natural_compare.dart';

import '../entities/gallery_item.dart';
import '../value_objects/gallery_sort.dart';

abstract final class GalleryItemSortRules {
  static int compareMedia(MediaItem left, MediaItem right, GallerySort sort) {
    final comparison = switch (sort) {
      GallerySort.nameAscending => naturalCompare(left.name, right.name),
      GallerySort.nameDescending => naturalCompare(right.name, left.name),
      GallerySort.newest => right.modifiedAt.compareTo(left.modifiedAt),
      GallerySort.oldest => left.modifiedAt.compareTo(right.modifiedAt),
    };
    if (comparison != 0) return comparison;
    return naturalCompare(left.path, right.path);
  }
}
