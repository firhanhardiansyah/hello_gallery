enum GalleryStyleLevel {
  none,
  xs,
  sm,
  standard,
  lg,
  xl;

  static GalleryStyleLevel fromStorage(String? value) {
    for (final level in GalleryStyleLevel.values) {
      if (level.name == value) return level;
    }
    return GalleryStyleLevel.standard;
  }

  String get label => switch (this) {
    GalleryStyleLevel.none => 'None',
    GalleryStyleLevel.xs => 'XS',
    GalleryStyleLevel.sm => 'SM',
    GalleryStyleLevel.standard => 'Default',
    GalleryStyleLevel.lg => 'LG',
    GalleryStyleLevel.xl => 'XL',
  };

  double get gridSpacing => switch (this) {
    GalleryStyleLevel.none => 0,
    GalleryStyleLevel.xs => 1,
    GalleryStyleLevel.sm => 2,
    GalleryStyleLevel.standard => 4,
    GalleryStyleLevel.lg => 8,
    GalleryStyleLevel.xl => 12,
  };

  double get cornerRadius => switch (this) {
    GalleryStyleLevel.none => 0,
    GalleryStyleLevel.xs => 2,
    GalleryStyleLevel.sm => 4,
    GalleryStyleLevel.standard => 8,
    GalleryStyleLevel.lg => 12,
    GalleryStyleLevel.xl => 16,
  };
}
