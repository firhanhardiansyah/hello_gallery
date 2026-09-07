import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/domain/repositories/seek_preview_frame_repository.dart';
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
      const Duration(seconds: 19),
    );
    expect(
      controller.bucketFor(
        const Duration(seconds: 19),
        const Duration(minutes: 30),
      ),
      const Duration(seconds: 20),
    );
    expect(
      controller.bucketFor(
        const Duration(seconds: 19),
        const Duration(hours: 2),
      ),
      const Duration(seconds: 20),
    );
  });

  test('keeps only the latest request while extraction is running', () async {
    final firstRequest = Completer<SeekPreviewFrame?>();
    final requested = <Duration>[];
    final controller = SeekPreviewController(
      loadFrame: (position, {precise = false}) {
        requested.add(position);
        if (requested.length == 1) return firstRequest.future;
        return Future.value(_frame(position, [2], precise: precise));
      },
      debounceDuration: Duration.zero,
      exactDelay: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);

    controller.request(const Duration(seconds: 11), const Duration(minutes: 5));
    await Future<void>.delayed(Duration.zero);
    controller.request(const Duration(seconds: 27), const Duration(minutes: 5));
    await Future<void>.delayed(Duration.zero);
    firstRequest.complete(_frame(requested.first, [1]));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(requested, const [Duration(seconds: 11), Duration(seconds: 27)]);
    expect(controller.frameBytes, [2]);
    expect(controller.isLoading, isFalse);
  });

  test('replaces the coarse frame with an exact frame after idle', () async {
    final requested = <({Duration position, bool precise})>[];
    final controller = SeekPreviewController(
      loadFrame: (position, {precise = false}) async {
        requested.add((position: position, precise: precise));
        return _frame(position, [precise ? 2 : 1], precise: precise);
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
      (position: Duration(seconds: 12), precise: false),
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
        return _frame(position, [1], precise: precise);
      },
      debounceDuration: Duration.zero,
      exactDelay: Duration.zero,
      prefetchDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    controller.request(const Duration(seconds: 12), const Duration(minutes: 5));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(requested, const [
      (position: Duration(seconds: 12), precise: false),
      (position: Duration(seconds: 12), precise: true),
      (position: Duration(seconds: 13), precise: false),
      (position: Duration(seconds: 11), precise: false),
    ]);
  });

  test(
    'serializes native loads and keeps the latest rapid-hover request',
    () async {
      final firstRequest = Completer<SeekPreviewFrame?>();
      final requested = <Duration>[];
      var activeLoads = 0;
      var maximumActiveLoads = 0;
      final controller = SeekPreviewController(
        loadFrame: (position, {precise = false}) async {
          requested.add(position);
          activeLoads++;
          maximumActiveLoads = activeLoads > maximumActiveLoads
              ? activeLoads
              : maximumActiveLoads;
          final result = requested.length == 1
              ? await firstRequest.future
              : _frame(position, [requested.length], precise: precise);
          activeLoads--;
          return result;
        },
        debounceDuration: Duration.zero,
        exactDelay: const Duration(hours: 1),
      );
      addTearDown(controller.dispose);

      controller.request(
        const Duration(seconds: 1),
        const Duration(minutes: 5),
      );
      await Future<void>.delayed(Duration.zero);
      controller.request(
        const Duration(seconds: 20),
        const Duration(minutes: 5),
      );
      await Future<void>.delayed(Duration.zero);
      controller.request(
        const Duration(seconds: 40),
        const Duration(minutes: 5),
      );
      await Future<void>.delayed(Duration.zero);
      firstRequest.complete(_frame(const Duration(seconds: 1), [1]));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(maximumActiveLoads, 1);
      expect(requested, const [Duration(seconds: 1), Duration(seconds: 40)]);
      expect(controller.frameBytes, [2]);
    },
  );

  test('rejects a decoder frame far from its requested timestamp', () async {
    final controller = SeekPreviewController(
      loadFrame: (position, {precise = false}) async => SeekPreviewFrame(
        bytes: Uint8List.fromList([1]),
        requestedPosition: position,
        actualPosition: position - const Duration(seconds: 4),
        precise: precise,
      ),
      debounceDuration: Duration.zero,
      exactDelay: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);

    controller.request(const Duration(seconds: 10), const Duration(minutes: 5));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.frameBytes, isNull);
  });
}

SeekPreviewFrame _frame(
  Duration position,
  List<int> bytes, {
  bool precise = false,
}) => SeekPreviewFrame(
  bytes: Uint8List.fromList(bytes),
  requestedPosition: position,
  actualPosition: position,
  precise: precise,
);
