import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_shell_top_bar.dart';
import 'package:hello_gallery/core/widgets/desktop_window_title_bar.dart';

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
              isFullscreen: false,
              previewTitle: null,
              sidebarVisible: true,
              windowPlatform: DesktopWindowPlatform.macOS,
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
    expect(
      find.byKey(const ValueKey('gallery-shell-top-bar-border')),
      findsOneWidget,
    );
    expect(find.byTooltip('New folder'), findsNothing);
    expect(find.byTooltip('Hide sidebar'), findsOneWidget);

    await tester.tap(find.text('Select all'));
    await tester.tap(find.byTooltip('Clear selection'));

    expect(selectAllCount, 1);
    expect(clearCount, 1);
  });

  testWidgets('hides Windows caption controls while fullscreen', (
    tester,
  ) async {
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
              isFullscreen: true,
              previewTitle: null,
              sidebarVisible: true,
              windowPlatform: DesktopWindowPlatform.windows,
              onToggleSidebar: () {},
              onClosePreview: () {},
              onGroupMedia: () {},
              onCreateFolder: () {},
              selectedItemCount: 0,
              totalItemCount: 0,
              onSelectAll: () {},
              onClearSelection: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DesktopWindowsCaptionControls), findsNothing);
    expect(find.byTooltip('View options'), findsOneWidget);

    await tester.tap(find.byTooltip('View options'));
    await tester.pumpAndSettle();

    expect(find.text('Show item names'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(
      find.ancestor(of: find.byType(Switch), matching: find.byType(InkWell)),
      findsNothing,
    );

    await tester.tap(find.text('Show item names'));
    await tester.pump();
    expect(find.text('Show item names'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Show item names'), findsNothing);
  });
}
