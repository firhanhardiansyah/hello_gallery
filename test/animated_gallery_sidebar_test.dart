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
}
