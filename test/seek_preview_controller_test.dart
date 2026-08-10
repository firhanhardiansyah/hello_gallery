import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/presentation/controllers/seek_preview_controller.dart';

void main() {
  test('uses adaptive timestamp buckets for video duration', () {
    final controller = SeekPreviewController(
      loadFrame: (_) async => null,
      debounceDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    expect(
      controller.bucketFor(
        const Duration(seconds: 19),
        const Duration(minutes: 5),
      ),
      const Duration(seconds: 15),
    );
    expect(
      controller.bucketFor(
        const Duration(seconds: 19),
        const Duration(minutes: 30),
      ),
      const Duration(seconds: 10),
    );
    expect(
      controller.bucketFor(
        const Duration(seconds: 19),
        const Duration(hours: 2),
      ),
      Duration.zero,
    );
  });

  test('keeps only the latest request while extraction is running', () async {
    final firstRequest = Completer<Uint8List?>();
    final requested = <Duration>[];
    final controller = SeekPreviewController(
      loadFrame: (position) {
        requested.add(position);
        if (requested.length == 1) return firstRequest.future;
        return Future.value(Uint8List.fromList([2]));
      },
      debounceDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    controller.request(const Duration(seconds: 11), const Duration(minutes: 5));
    await Future<void>.delayed(Duration.zero);
    controller.request(const Duration(seconds: 27), const Duration(minutes: 5));
    await Future<void>.delayed(Duration.zero);
    firstRequest.complete(Uint8List.fromList([1]));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(requested, const [Duration(seconds: 10), Duration(seconds: 25)]);
    expect(controller.frameBytes, [2]);
    expect(controller.isLoading, isFalse);
  });

  test('prefetches adjacent buckets after the cursor stays idle', () async {
    final requested = <Duration>[];
    final controller = SeekPreviewController(
      loadFrame: (position) async {
        requested.add(position);
        return Uint8List.fromList([1]);
      },
      debounceDuration: Duration.zero,
      prefetchDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    controller.request(const Duration(seconds: 12), const Duration(minutes: 5));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(requested, const [
      Duration(seconds: 10),
      Duration(seconds: 15),
      Duration(seconds: 5),
    ]);
  });
}
