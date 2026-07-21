import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/media_preview/presentation/notifiers/media_preview_notifier.dart';
import 'package:hello_gallery/features/media_preview/presentation/states/media_preview_ui_state.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/video_controls.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('loop button delegates to the media preview notifier', (
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
              state: MediaPreviewUiState(duration: Duration(minutes: 1)),
              onInteraction: _noop,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Loop video'));
    await tester.pump();

    expect(container.read(mediaPreviewNotifierProvider).isLooping, isTrue);
  });
}

void _noop() {}
