import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/presentation/states/media_preview_ui_state.dart';

void main() {
  test('video loop is off by default and can be enabled', () {
    const initial = MediaPreviewUiState();

    expect(initial.isLooping, isFalse);
    expect(initial.copyWith(isLooping: true).isLooping, isTrue);
  });
}
