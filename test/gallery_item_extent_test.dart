import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_item_extent.dart';

void main() {
  test('moves through bounded gallery item size levels', () {
    expect(GalleryItemExtent.increase(320), 400);
    expect(GalleryItemExtent.increase(520), 520);
    expect(GalleryItemExtent.decrease(320), 240);
    expect(GalleryItemExtent.decrease(160), 160);
  });

  test('normalizes persisted values to the nearest supported size', () {
    expect(GalleryItemExtent.normalize(null), 320);
    expect(GalleryItemExtent.normalize(double.nan), 320);
    expect(GalleryItemExtent.normalize(405), 400);
  });
}
