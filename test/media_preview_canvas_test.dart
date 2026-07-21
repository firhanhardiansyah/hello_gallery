import 'package:flutter/material.dart';
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
  });
}
