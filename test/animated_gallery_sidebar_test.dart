import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/animated_gallery_sidebar.dart';

void main() {
  testWidgets('animates sidebar width while preserving its child', (
    tester,
  ) async {
    Widget buildSidebar({required bool visible}) => MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: Row(
          children: [
            AnimatedGallerySidebar(
              visible: visible,
              child: const SizedBox(
                key: ValueKey('sidebar-content'),
                height: 400,
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(buildSidebar(visible: true));
    expect(tester.getSize(find.byType(AnimatedGallerySidebar)).width, 300);

    await tester.pumpWidget(buildSidebar(visible: false));
    await tester.pump(const Duration(milliseconds: 120));
    final animatedWidth = tester
        .getSize(find.byType(AnimatedGallerySidebar))
        .width;
    expect(animatedWidth, greaterThan(0));
    expect(animatedWidth, lessThan(300));

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedGallerySidebar)).width, 0);
    expect(find.byKey(const ValueKey('sidebar-content')), findsOneWidget);
  });

  testWidgets('requires extra drag distance before hiding at minimum width', (
    tester,
  ) async {
    var visible = true;
    var width = AnimatedGallerySidebar.defaultWidth;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                AnimatedGallerySidebar(
                  visible: visible,
                  width: width,
                  onWidthChanged: (value) => setState(() => width = value),
                  onMinWidthReached: () => setState(() => visible = false),
                  child: const SizedBox(height: 400),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final handle = find.byKey(const ValueKey('gallery-sidebar-resize-handle'));
    await tester.drag(handle, const Offset(80, 0));
    await tester.pump();

    expect(width, 380);
    expect(tester.getSize(find.byType(AnimatedGallerySidebar)).width, 380);

    final dragIntoCollapseResistance =
        width -
        AnimatedGallerySidebar.minimumWidth +
        AnimatedGallerySidebar.defaultCollapseDragDistance / 2;
    await tester.drag(handle, Offset(-dragIntoCollapseResistance, 0));
    await tester.pump();

    expect(visible, isTrue);
    expect(width, AnimatedGallerySidebar.minimumWidth);
    expect(
      tester.getSize(find.byType(AnimatedGallerySidebar)).width,
      AnimatedGallerySidebar.minimumWidth,
    );

    await tester.drag(
      handle,
      const Offset(-AnimatedGallerySidebar.defaultCollapseDragDistance - 1, 0),
    );
    await tester.pumpAndSettle();

    expect(visible, isFalse);
    expect(width, AnimatedGallerySidebar.minimumWidth);
    expect(tester.getSize(find.byType(AnimatedGallerySidebar)).width, 0);
  });
}
