import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/media_preview/presentation/notifiers/media_preview_notifier.dart';
import 'package:hello_gallery/features/media_preview/presentation/states/media_preview_ui_state.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/video_controls.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('video control actions delegate to their owners', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      mediaPreviewNotifierProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    var fullscreenCount = 0;
    var rotateCount = 0;
    var rotationLockCount = 0;
    var filmstripCount = 0;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: VideoControls(
              state: const MediaPreviewUiState(duration: Duration(minutes: 1)),
              isFullscreen: false,
              isRotationLocked: false,
              filmstripVisible: true,
              onInteraction: _noop,
              onRotate: () => rotateCount++,
              onToggleRotationLock: () => rotationLockCount++,
              onToggleFilmstrip: () => filmstripCount++,
              onToggleFullscreen: () => fullscreenCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Loop video'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('video-secondary-controls')),
      findsOneWidget,
    );
    expect(find.text('00:00 / 01:00'), findsOneWidget);
    final loopButton = find.byTooltip('Loop video');
    final rotateButton = find.byTooltip('Rotate clockwise');
    final rotationLockButton = find.byTooltip('Lock rotation');
    final filmstripButton = find.byTooltip('Hide media list (G)');
    final fullscreenButton = find.byTooltip('Fullscreen');
    expect(
      tester.getCenter(loopButton).dx,
      lessThan(tester.getCenter(rotateButton).dx),
    );
    expect(
      tester.getCenter(rotateButton).dx,
      lessThan(tester.getCenter(rotationLockButton).dx),
    );
    expect(
      tester.getCenter(rotationLockButton).dx,
      lessThan(tester.getCenter(filmstripButton).dx),
    );
    expect(
      tester.getCenter(filmstripButton).dx,
      lessThan(tester.getCenter(fullscreenButton).dx),
    );
    expect(container.read(mediaPreviewNotifierProvider).isLooping, isTrue);
    await tester.tap(rotateButton);
    expect(rotateCount, 1);
    await tester.tap(rotationLockButton);
    expect(rotationLockCount, 1);
    await tester.tap(filmstripButton);
    expect(filmstripCount, 1);
    await tester.tap(fullscreenButton);
    expect(fullscreenCount, 1);
  });

  testWidgets('includes hours when the video is at least one hour long', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      mediaPreviewNotifierProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: const Scaffold(
            body: VideoControls(
              state: MediaPreviewUiState(
                position: Duration(minutes: 2),
                duration: Duration(hours: 1, minutes: 1),
              ),
              isFullscreen: false,
              isRotationLocked: false,
              filmstripVisible: false,
              onInteraction: _noop,
              onRotate: _noop,
              onToggleRotationLock: _noop,
              onToggleFilmstrip: _noop,
              onToggleFullscreen: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.text('00:02:00 / 01:01:00'), findsOneWidget);
  });
}

void _noop() {}
