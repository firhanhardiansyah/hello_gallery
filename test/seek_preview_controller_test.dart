import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/presentation/controllers/seek_preview_controller.dart';

void main() {
  test('uses adaptive timestamp buckets for video duration', () {
    final controller = SeekPreviewController(
      loadFrame: (_, {precise = false}) async => null,
      debounceDuration: Duration.zero,
      exactDelay: const Duration(hours: 1),
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
      loadFrame: (position, {precise = false}) {
        requested.add(position);
        if (requested.length == 1) return firstRequest.future;
        return Future.value(Uint8List.fromList([2]));
      },
      debounceDuration: Duration.zero,
      exactDelay: const Duration(hours: 1),
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

  test('replaces the coarse frame with an exact frame after idle', () async {
    final requested = <({Duration position, bool precise})>[];
    final controller = SeekPreviewController(
      loadFrame: (position, {precise = false}) async {
        requested.add((position: position, precise: precise));
        return Uint8List.fromList([precise ? 2 : 1]);
      },
      debounceDuration: Duration.zero,
      exactDelay: const Duration(milliseconds: 10),
      prefetchDelay: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);

    controller.request(
      const Duration(milliseconds: 12345),
      const Duration(minutes: 5),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));

    expect(controller.frameBytes, [1]);
    expect(requested, const [
      (position: Duration(seconds: 10), precise: false),
    ]);

    await Future<void>.delayed(const Duration(milliseconds: 15));

    expect(controller.frameBytes, [2]);
    expect(requested.last, const (
      position: Duration(milliseconds: 12345),
      precise: true,
    ));
  });

  test('prefetches adjacent coarse buckets after exact extraction', () async {
    final requested = <({Duration position, bool precise})>[];
    final controller = SeekPreviewController(
      loadFrame: (position, {precise = false}) async {
        requested.add((position: position, precise: precise));
        return Uint8List.fromList([1]);
      },
      debounceDuration: Duration.zero,
      exactDelay: Duration.zero,
      prefetchDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    controller.request(const Duration(seconds: 12), const Duration(minutes: 5));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(requested, const [
      (position: Duration(seconds: 10), precise: false),
      (position: Duration(seconds: 12), precise: true),
      (position: Duration(seconds: 15), precise: false),
      (position: Duration(seconds: 5), precise: false),
    ]);
  });
}
