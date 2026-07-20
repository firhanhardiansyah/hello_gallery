import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_breadcrumb.dart';

void main() {
  testWidgets('opens an ancestor folder when its segment is tapped', (
    tester,
  ) async {
    String? selectedPath;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GalleryBreadcrumb(
            rootPath: '/gallery/Wallpapers',
            currentPath: '/gallery/Wallpapers/One Piece',
            onPathSelected: (path) => selectedPath = path,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Wallpapers'));

    expect(selectedPath, '/gallery/Wallpapers');
  });

  testWidgets('keeps the current folder segment non-interactive', (
    tester,
  ) async {
    String? selectedPath;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GalleryBreadcrumb(
            rootPath: '/gallery/Wallpapers',
            currentPath: '/gallery/Wallpapers/One Piece',
            onPathSelected: (path) => selectedPath = path,
          ),
        ),
      ),
    );

    await tester.tap(find.text('One Piece'));

    expect(selectedPath, isNull);
  });
}
