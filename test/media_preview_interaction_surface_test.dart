import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/presentation/widgets/media_preview_interaction_surface.dart';

void main() {
  testWidgets(
    'double click triggers fullscreen without triggering single tap',
    (tester) async {
      var tapCount = 0;
      var doubleTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaPreviewInteractionSurface(
            onTap: () => tapCount++,
            onDoubleTap: () => doubleTapCount++,
            child: const SizedBox.expand(),
          ),
        ),
      );

      await tester.tap(find.byType(MediaPreviewInteractionSurface));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(MediaPreviewInteractionSurface));
    await tester.pump(const Duration(milliseconds: 100));

      expect(doubleTapCount, 1);
      expect(tapCount, 0);
    },
  );
}
