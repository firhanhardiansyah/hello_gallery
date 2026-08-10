import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/core/window/desktop_window_config.dart';

void main() {
  test('keeps enough minimum space for desktop gallery chrome', () {
    expect(DesktopWindowConfig.minimumSize.width, 960);
    expect(DesktopWindowConfig.minimumSize.height, 600);
  });
}
