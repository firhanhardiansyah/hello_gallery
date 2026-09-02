import 'package:hello_gallery/core/utils/natural_compare.dart';

import '../entities/gallery_item.dart';
import '../value_objects/gallery_sort.dart';

abstract final class GalleryItemSortRules {
  static int compareFolders(
    GalleryFolder left,
    GalleryFolder right,
    GallerySort sort,
  ) {
    final comparison = _compare(
      leftName: left.name,
      rightName: right.name,
      leftModifiedAt: left.modifiedAt,
      rightModifiedAt: right.modifiedAt,
      sort: sort,
    );
    if (comparison != 0) return comparison;
    return naturalCompare(left.path, right.path);
  }

  static int compareMedia(MediaItem left, MediaItem right, GallerySort sort) {
    final comparison = _compare(
      leftName: left.name,
      rightName: right.name,
      leftModifiedAt: left.modifiedAt,
      rightModifiedAt: right.modifiedAt,
      sort: sort,
    );
    if (comparison != 0) return comparison;
    return naturalCompare(left.path, right.path);
  }

  static int _compare({
    required String leftName,
    required String rightName,
    required DateTime leftModifiedAt,
    required DateTime rightModifiedAt,
    required GallerySort sort,
  }) => switch (sort) {
    GallerySort.nameAscending => naturalCompare(leftName, rightName),
    GallerySort.nameDescending => naturalCompare(rightName, leftName),
    GallerySort.newest => rightModifiedAt.compareTo(leftModifiedAt),
    GallerySort.oldest => leftModifiedAt.compareTo(rightModifiedAt),
  };
}
