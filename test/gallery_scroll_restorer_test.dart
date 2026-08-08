import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/coordinators/gallery_scroll_restorer.dart';

void main() {
  testWidgets('restores the saved offset after preview closes', (tester) async {
    final controller = ScrollController(keepScrollOffset: false);
    var mounted = true;
    var previewActive = false;
    final restorer = GalleryScrollRestorer(
      scrollController: controller,
      isMounted: () => mounted,
      isPreviewActive: () => previewActive,
    );
    addTearDown(() {
      mounted = false;
      restorer.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(_scrollView(controller, itemCount: 100));
    controller.jumpTo(1200);
    restorer.captureBeforePreview();
    previewActive = true;
    await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));

    previewActive = false;
    restorer.restoreAfterPreview();
    await tester.pumpWidget(_scrollView(controller, itemCount: 2));
    await tester.pump();
    expect(controller.offset, lessThan(1200));

    await tester.pumpWidget(_scrollView(controller, itemCount: 100));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(controller.offset, 1200);
  });
}

Widget _scrollView(ScrollController controller, {required int itemCount}) {
  return MaterialApp(
    home: ListView.builder(
      controller: controller,
      itemExtent: 100,
      itemCount: itemCount,
      itemBuilder: (context, index) => Text('$index'),
    ),
  );
}
