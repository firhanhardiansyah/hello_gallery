class MediaDimensions {
  const MediaDimensions({required this.width, required this.height})
    : assert(width > 0),
      assert(height > 0);

  final int width;
  final int height;

  double get aspectRatio => width / height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaDimensions &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}
