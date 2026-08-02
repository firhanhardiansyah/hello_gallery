import '../../../gallery/domain/value_objects/gallery_item_extent.dart';
import '../../../gallery/domain/value_objects/gallery_layout_mode.dart';

class GalleryViewPreferences {
  const GalleryViewPreferences({
    this.showItemNames = true,
    this.layoutMode = GalleryLayoutMode.grid,
    this.itemExtent = GalleryItemExtent.defaultValue,
  });

  final bool showItemNames;
  final GalleryLayoutMode layoutMode;
  final double itemExtent;
}
