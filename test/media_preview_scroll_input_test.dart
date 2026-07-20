import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/presentation/input/media_preview_scroll_input.dart';

void main() {
  test('accumulates small trackpad deltas into one next navigation', () {
    final input = MediaPreviewScrollInput();
    addTearDown(input.dispose);

    expect(input.handle(const Offset(0, 10)), 0);
    expect(input.handle(const Offset(0, 14)), 1);
    expect(input.handle(const Offset(0, 100)), 0);
  });

  test('uses the dominant axis and resets after the gesture ends', () async {
    final input = MediaPreviewScrollInput(
      resetDelay: const Duration(milliseconds: 10),
    );
    addTearDown(input.dispose);

    expect(input.handle(const Offset(30, 5)), 1);
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(input.handle(const Offset(-30, 5)), -1);
  });
}
