import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_shell_top_bar.dart';

void main() {
  testWidgets('replaces gallery actions with selection information', (
    tester,
  ) async {
    var selectAllCount = 0;
    var clearCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GalleryShellTopBar(
              gallery: const GalleryUiState(
                status: GalleryStatus.ready,
                rootPath: '/gallery',
                currentPath: '/gallery',
              ),
              isPreview: false,
              previewTitle: null,
              sidebarVisible: true,
              onToggleSidebar: () {},
              onClosePreview: () {},
              onGroupMedia: () {},
              onCreateFolder: () {},
              selectedItemCount: 3,
              totalItemCount: 8,
              onSelectAll: () => selectAllCount++,
              onClearSelection: () => clearCount++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('3 items selected'), findsOneWidget);
    expect(find.byTooltip('New folder'), findsNothing);

    await tester.tap(find.text('Select all'));
    await tester.tap(find.byTooltip('Clear selection'));

    expect(selectAllCount, 1);
    expect(clearCount, 1);
  });
}
