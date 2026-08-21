import '../../../gallery/domain/value_objects/gallery_item_extent.dart';
import '../../../gallery/domain/value_objects/gallery_layout_mode.dart';
import '../../../gallery/domain/value_objects/gallery_sort.dart';

class GalleryViewPreferences {
  const GalleryViewPreferences({
    this.showItemNames = true,
    this.layoutMode = GalleryLayoutMode.grid,
    this.itemExtent = GalleryItemExtent.defaultValue,
    this.sort = GallerySort.nameAscending,
  });

  final bool showItemNames;
  final GalleryLayoutMode layoutMode;
  final double itemExtent;
  final GallerySort sort;
}
