import '../../../gallery/domain/value_objects/gallery_layout_mode.dart';

class GalleryViewPreferences {
  const GalleryViewPreferences({
    this.showItemNames = true,
    this.layoutMode = GalleryLayoutMode.grid,
  });

  final bool showItemNames;
  final GalleryLayoutMode layoutMode;
}
