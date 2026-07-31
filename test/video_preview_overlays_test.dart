import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/media_preview/presentation/notifiers/media_preview_notifier.dart';
import 'package:hello_gallery/features/media_preview/presentation/states/media_preview_ui_state.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/video_preview_overlays.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('_VideoPlaybackButton visibility hides faster than overall controls', (
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
          home: Scaffold(
            body: Stack(
              children: [
                VideoPreviewOverlays(
                  itemPath: 'test.mp4',
                  thumbnailPath: null,
                  state: const MediaPreviewUiState(
                    isPlaying: true,
                    isVideoReady: true,
                  ),
                  controlsVisible: true,
                  isFullscreen: false,
                  rotationQuarterTurns: 0,
                  isRotationLocked: false,
                  filmstripVisible: false,
                  hdrPlaybackEnabled: false,
                  onTogglePlayback: _noop,
                  onRotate: _noop,
                  onToggleRotationLock: _noop,
                  onToggleFilmstrip: _noop,
                  onToggleHdrPlayback: _noop,
                  onToggleFullscreen: _noop,
                  onInteraction: _noop,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final buttonFinder = find.byTooltip('Pause').first;

    // Initially, button opacity is 1
    AnimatedOpacity animatedOpacity = tester.widget(
      find
          .ancestor(
            of: buttonFinder,
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(animatedOpacity.opacity, 1.0);

    // Advance 250ms (playback button hide duration)
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 150)); // animation duration

    animatedOpacity = tester.widget(
      find
          .ancestor(
            of: buttonFinder,
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(animatedOpacity.opacity, 0.0);

    // Hovering / rebuilding with controlsVisible: true does NOT re-show the button
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: Stack(
              children: [
                VideoPreviewOverlays(
                  itemPath: 'test.mp4',
                  thumbnailPath: null,
                  state: const MediaPreviewUiState(
                    isPlaying: true,
                    isVideoReady: true,
                  ),
                  controlsVisible: true,
                  isFullscreen: false,
                  rotationQuarterTurns: 0,
                  isRotationLocked: false,
                  filmstripVisible: false,
                  hdrPlaybackEnabled: false,
                  onTogglePlayback: _noop,
                  onRotate: _noop,
                  onToggleRotationLock: _noop,
                  onToggleFilmstrip: _noop,
                  onToggleHdrPlayback: _noop,
                  onToggleFullscreen: _noop,
                  onInteraction: _noop,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    animatedOpacity = tester.widget(
      find
          .ancestor(
            of: buttonFinder,
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(animatedOpacity.opacity, 0.0);
  });
}

void _noop() {}
