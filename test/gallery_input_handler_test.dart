import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/input/gallery_input_handler.dart';

void main() {
  test('ignores gallery shortcuts while input handling is disabled', () {
    var enabled = false;
    var sidebarCount = 0;
    var fullscreenCount = 0;
    final handler = GalleryInputHandler(
      isEnabled: () => enabled,
      onMoveUp: _noop,
      onMoveDown: _noop,
      onMoveLeft: _noop,
      onMoveRight: _noop,
      onActivate: _noop,
      onBack: _noop,
      onToggleSelectAll: _noop,
      onToggleSidebar: () => sidebarCount++,
      onToggleFullscreen: () => fullscreenCount++,
    );
    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyS)),
      KeyEventResult.ignored,
    );
    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyF)),
      KeyEventResult.ignored,
    );
    expect(sidebarCount, 0);
    expect(fullscreenCount, 0);

    enabled = true;
    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyS)),
      KeyEventResult.handled,
    );
    expect(sidebarCount, 1);
  });

  testWidgets('toggles select all with Control or Command plus A', (
    tester,
  ) async {
    var toggleCount = 0;
    final handler = GalleryInputHandler(
      isEnabled: () => true,
      onMoveUp: _noop,
      onMoveDown: _noop,
      onMoveLeft: _noop,
      onMoveRight: _noop,
      onActivate: _noop,
      onBack: _noop,
      onToggleSelectAll: () => toggleCount++,
      onToggleSidebar: _noop,
      onToggleFullscreen: _noop,
    );

    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyA)),
      KeyEventResult.ignored,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyA)),
      KeyEventResult.handled,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    expect(
      handler.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyA)),
      KeyEventResult.handled,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

    expect(toggleCount, 2);
  });
}

KeyDownEvent _keyDown(LogicalKeyboardKey key) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: key,
  timeStamp: Duration.zero,
);

void _noop() {}
