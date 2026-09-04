import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('secondary click reports the pointer position', (tester) async {
    TapDownDetails? receivedDetails;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaPreviewInteractionSurface(
          onDoubleTap: () {},
          onSecondaryTapDown: (details) => receivedDetails = details,
          child: const SizedBox.expand(),
        ),
      ),
    );

    const position = Offset(120, 160);
    await tester.tapAt(position, buttons: kSecondaryButton);
    await tester.pump();

    expect(receivedDetails?.globalPosition, position);
  });
}
