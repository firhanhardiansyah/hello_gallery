import '../../../gallery/domain/value_objects/gallery_item_extent.dart';
import '../../../gallery/domain/value_objects/gallery_layout_mode.dart';
import '../../../gallery/domain/value_objects/gallery_sort.dart';
import '../../../gallery/domain/value_objects/gallery_style_level.dart';

class GalleryViewPreferences {
  const GalleryViewPreferences({
    this.showItemNames = true,
    this.layoutMode = GalleryLayoutMode.grid,
    this.itemExtent = GalleryItemExtent.defaultValue,
    this.sort = GallerySort.nameAscending,
    this.gridSpacing = GalleryStyleLevel.standard,
    this.cornerRadius = GalleryStyleLevel.standard,
    this.mediaPreviewFilmstripEnabled = true,
  });

  final bool showItemNames;
  final GalleryLayoutMode layoutMode;
  final double itemExtent;
  final GallerySort sort;
  final GalleryStyleLevel gridSpacing;
  final GalleryStyleLevel cornerRadius;
  final bool mediaPreviewFilmstripEnabled;
}
