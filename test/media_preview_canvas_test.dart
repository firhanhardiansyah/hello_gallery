import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/media_preview_canvas.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('rotates media layout by quarter turns', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.dark,
        ),
        home: const MediaPreviewCanvas(
          itemPath: '/gallery/video.mp4',
          isVideo: true,
          videoController: null,
          rotationQuarterTurns: 1,
        ),
      ),
    );

    final rotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
    expect(rotatedBox.quarterTurns, 1);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.scaleFactor, 400);
  });

  testWidgets('zooms video with primary-modifier scroll', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.dark,
        ),
        home: const MediaPreviewCanvas(
          itemPath: '/gallery/video.mp4',
          isVideo: true,
          videoController: null,
          rotationQuarterTurns: 0,
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(400, 300),
        scrollDelta: Offset(0, -20),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );

    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  });

  testWidgets('plain scroll keeps the canvas at fit scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.dark,
        ),
        home: const MediaPreviewCanvas(
          itemPath: '/gallery/video.mp4',
          isVideo: true,
          videoController: null,
          rotationQuarterTurns: 0,
        ),
      ),
    );

    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(400, 300),
        scrollDelta: Offset(0, -20),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.transformationController!.value, Matrix4.identity());
  });

  testWidgets('resets zoom when media rotation changes', (tester) async {
    Widget previewWithRotation(int quarterTurns) => MaterialApp(
      theme: buildAppTheme(
        colorTheme: AppColorTheme.indigo,
        brightness: Brightness.dark,
      ),
      home: MediaPreviewCanvas(
        itemPath: '/gallery/video.mp4',
        isVideo: true,
        videoController: null,
        rotationQuarterTurns: quarterTurns,
      ),
    );

    await tester.pumpWidget(previewWithRotation(0));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(400, 300),
        scrollDelta: Offset(0, -20),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    var viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );

    await tester.pumpWidget(previewWithRotation(1));
    viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.transformationController!.value, Matrix4.identity());

    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  });

  testWidgets('shows a fallback when the preview image no longer exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          colorTheme: AppColorTheme.indigo,
          brightness: Brightness.dark,
        ),
        home: const MediaPreviewCanvas(
          itemPath: 'missing-preview-image.jpg',
          isVideo: false,
          videoController: null,
          rotationQuarterTurns: 0,
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('media-preview-image-unavailable')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
