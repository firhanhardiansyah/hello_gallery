abstract final class GalleryItemExtent {
  static const defaultValue = 320.0;
  static const values = <double>[160, 200, 240, defaultValue, 400, 520];

  static double increase(double current) {
    return values.firstWhere(
      (value) => value > current,
      orElse: () => values.last,
    );
  }

  static double decrease(double current) {
    return values.lastWhere(
      (value) => value < current,
      orElse: () => values.first,
    );
  }

  static double normalize(double? value) {
    if (value == null || !value.isFinite) return defaultValue;
    return values.reduce(
      (closest, candidate) =>
          (candidate - value).abs() < (closest - value).abs()
          ? candidate
          : closest,
    );
  }
}
