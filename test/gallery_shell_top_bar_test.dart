import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/features/gallery/presentation/states/gallery_ui_state.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_page/gallery_shell_top_bar.dart';
import 'package:hello_gallery/core/widgets/desktop_window_title_bar.dart';
import 'package:hello_gallery/core/widgets/media_overlay_icon_button.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('replaces gallery actions with selection information', (
    tester,
  ) async {
    var selectAllCount = 0;
    var clearCount = 0;
    var deleteCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: GalleryShellTopBar(
              gallery: const GalleryUiState(
                loadState: GalleryLoadState.ready(),
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
              selectedMediaCount: 3,
              onDeleteSelectedMedia: () => deleteCount++,
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
    await tester.tap(find.byTooltip('Move selected files to Trash'));

    expect(selectAllCount, 1);
    expect(clearCount, 1);
    expect(deleteCount, 1);
  });

  testWidgets('hides Windows caption controls while fullscreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: GalleryShellTopBar(
              gallery: const GalleryUiState(
                loadState: GalleryLoadState.ready(),
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
              selectedMediaCount: 0,
              onDeleteSelectedMedia: () {},
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
    expect(find.text('Hide item names'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);

    await tester.tap(find.text('Hide item names'));
    await tester.pumpAndSettle();
    expect(find.text('Show item names'), findsNothing);
  });

  testWidgets('keeps preview actions out of the top bar', (tester) async {
    var closeCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: GalleryShellTopBar(
              gallery: const GalleryUiState(
                loadState: GalleryLoadState.ready(),
                rootPath: '/gallery',
                currentPath: '/gallery',
              ),
              isPreview: true,
              isFullscreen: false,
              previewTitle: 'video.mp4',
              sidebarVisible: true,
              windowPlatform: DesktopWindowPlatform.macOS,
              onToggleSidebar: () {},
              onClosePreview: () => closeCount++,
              onGroupMedia: () {},
              onCreateFolder: () {},
              selectedItemCount: 0,
              totalItemCount: 1,
              onSelectAll: () {},
              onClearSelection: () {},
              selectedMediaCount: 0,
              onDeleteSelectedMedia: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Enable HDR playback'), findsNothing);
    expect(find.byTooltip('Close detail'), findsNothing);
    expect(find.byTooltip('Back to gallery'), findsOneWidget);
    expect(find.byType(MediaOverlayIconButton), findsNWidgets(3));
    expect(
      tester
          .widget<DesktopWindowTitleBar>(find.byType(DesktopWindowTitleBar))
          .backgroundColor,
      Colors.transparent,
    );
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('preview-title')),
    );
    expect(title.style?.color, AppColorTokens.light.onMedia);
    expect(
      find.byKey(const ValueKey('gallery-shell-top-bar-border')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Back to gallery'));
    expect(closeCount, 1);
  });

  testWidgets('uses light Windows caption icons over preview media', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: GalleryShellTopBar(
              gallery: const GalleryUiState(
                loadState: GalleryLoadState.ready(),
                rootPath: '/gallery',
                currentPath: '/gallery',
              ),
              isPreview: true,
              isFullscreen: false,
              previewTitle: 'video.mp4',
              sidebarVisible: true,
              windowPlatform: DesktopWindowPlatform.windows,
              onToggleSidebar: () {},
              onClosePreview: () {},
              onGroupMedia: () {},
              onCreateFolder: () {},
              selectedItemCount: 0,
              totalItemCount: 1,
              onSelectAll: () {},
              onClearSelection: () {},
              selectedMediaCount: 0,
              onDeleteSelectedMedia: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<DesktopWindowsCaptionControls>(
            find.byType(DesktopWindowsCaptionControls),
          )
          .brightness,
      Brightness.dark,
    );
  });
}
