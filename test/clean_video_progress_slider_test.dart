import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/clean_video_progress_slider.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('reveals progress on bottom hover and hides it on exit', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSlider(onChanged: (_) {}));

    final track = find.byKey(const ValueKey('clean-video-progress-track'));
    AnimatedOpacity opacity() => tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('clean-video-progress-opacity')),
    );
    expect(tester.getSize(track).height, 3);
    expect(opacity().opacity, 0);
    expect(
      find.byKey(const ValueKey('clean-video-progress-thumb')),
      findsNothing,
    );

    final region = find.byKey(
      const ValueKey('clean-video-progress-hover-region'),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(region));
    await tester.pumpAndSettle();

    expect(tester.getSize(track).height, 6);
    expect(opacity().opacity, 1);
    expect(find.byKey(const ValueKey('clean-video-progress-thumb')), findsOne);

    await mouse.moveTo(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(opacity().opacity, 0);
    expect(
      find.byKey(const ValueKey('clean-video-progress-thumb')),
      findsNothing,
    );
  });

  testWidgets('seeks from the full-width clean progress surface', (
    tester,
  ) async {
    Duration? seekPosition;
    await tester.pumpWidget(
      _buildSlider(onChanged: (position) => seekPosition = position),
    );

    final region = find.byKey(
      const ValueKey('clean-video-progress-hover-region'),
    );
    final topLeft = tester.getTopLeft(region);
    final size = tester.getSize(region);
    await tester.tapAt(
      Offset(topLeft.dx + (size.width * 0.75), topLeft.dy + (size.height / 2)),
    );

    expect(seekPosition, const Duration(seconds: 90));
  });

  testWidgets('stays hidden until video duration is available', (tester) async {
    await tester.pumpWidget(
      _buildSlider(duration: Duration.zero, onChanged: (_) {}),
    );

    expect(
      find.byKey(const ValueKey('clean-video-progress-hover-region')),
      findsNothing,
    );
  });
}

Widget _buildSlider({
  Duration duration = const Duration(minutes: 2),
  required ValueChanged<Duration> onChanged,
}) => MaterialApp(
  theme: buildAppTheme(
    colorTheme: AppColorTheme.indigo,
    brightness: Brightness.dark,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 320,
        child: CleanVideoProgressSlider(
          position: const Duration(seconds: 30),
          duration: duration,
          onChanged: onChanged,
        ),
      ),
    ),
  ),
);
