import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/media_preview/domain/repositories/seek_preview_frame_repository.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/video_seek_slider.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('shows the hovered video duration above the slider', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.dark,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: VideoSeekSlider(
                position: Duration.zero,
                duration: const Duration(minutes: 2),
                onChanged: (_) {},
                onInteraction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final region = find.byKey(const ValueKey('video-seek-hover-region'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(region));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('video-seek-hover-label')),
      findsOneWidget,
    );
    expect(find.text('01:00'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('video-seek-hover-label')),
        matching: find.byType(Overlay),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getBottomLeft(find.byKey(const ValueKey('video-seek-hover-label')))
          .dy,
      lessThan(tester.getTopLeft(region).dy),
    );

    await mouse.moveTo(const Offset(10, 10));
    await tester.pump();

    expect(find.byKey(const ValueKey('video-seek-hover-label')), findsNothing);
  });

  testWidgets('shows a cached frame for the hovered timestamp', (tester) async {
    final frameBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final requestedPositions = <Duration>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.dark,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: VideoSeekSlider(
                position: Duration.zero,
                duration: const Duration(minutes: 2),
                previewIdentity: 'video.mp4',
                previewDebounce: Duration.zero,
                previewExactDelay: const Duration(hours: 1),
                previewFrameLoader: (position, {precise = false}) async {
                  requestedPositions.add(position);
                  return SeekPreviewFrame(
                    bytes: frameBytes,
                    requestedPosition: position,
                    actualPosition: position,
                    precise: precise,
                  );
                },
                onChanged: (_) {},
                onInteraction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final region = find.byKey(const ValueKey('video-seek-hover-region'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(region));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(requestedPositions, [const Duration(minutes: 1)]);
    expect(
      find.byKey(const ValueKey('video-seek-preview-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('video-seek-preview-frame')),
      findsOneWidget,
    );
    expect(find.text('01:00'), findsOneWidget);
  });
}
