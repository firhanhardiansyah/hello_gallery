import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_view_options_menu.dart';

void main() {
  testWidgets('combines sorting, item names, and layout in one menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: GalleryViewOptionsMenu())),
      ),
    );

    await tester.tap(find.byTooltip('View options'));
    await tester.pumpAndSettle();

    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('A–Z'), findsOneWidget);
    expect(find.text('Z–A'), findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);
    expect(find.text('Oldest'), findsOneWidget);
    expect(find.text('Item names'), findsOneWidget);
    expect(find.text('Show item names'), findsOneWidget);
    expect(find.text('Hide item names'), findsOneWidget);
    expect(find.text('Layout'), findsOneWidget);
    expect(find.text('Grid'), findsOneWidget);
    expect(find.text('Quilted'), findsOneWidget);
    expect(find.text('Masonry'), findsOneWidget);
  });
}
