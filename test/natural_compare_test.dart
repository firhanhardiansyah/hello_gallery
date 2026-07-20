import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/core/utils/natural_compare.dart';

void main() {
  test('sorts numbered media names in human order', () {
    final names = ['image10.jpg', 'image2.jpg', 'image1.jpg', 'image20.jpg'];

    names.sort(naturalCompare);

    expect(names, ['image1.jpg', 'image2.jpg', 'image10.jpg', 'image20.jpg']);
  });

  test('sorts case-insensitively and remains deterministic', () {
    final names = ['B2.jpg', 'a10.jpg', 'A2.jpg', 'a1.jpg'];

    names.sort(naturalCompare);

    expect(names, ['a1.jpg', 'A2.jpg', 'a10.jpg', 'B2.jpg']);
  });
}
