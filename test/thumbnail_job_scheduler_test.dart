import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/thumbnail/application/providers/thumbnail_dependencies.dart';
import 'package:hello_gallery/features/thumbnail/application/services/thumbnail_job_scheduler.dart';
import 'package:hello_gallery/features/thumbnail/domain/repositories/thumbnail_repository.dart';

void main() {
  test('uses file metadata as stable video thumbnail identity', () {
    final first = _video('video.mp4');
    final equivalent = _video('video.mp4');
    final modified = MediaItem(
      path: first.path,
      name: first.name,
      modifiedAt: first.modifiedAt.add(const Duration(seconds: 1)),
      mediaType: first.mediaType,
      sizeBytes: first.sizeBytes,
    );

    expect(equivalent, first);
    expect(videoThumbnailProvider(equivalent), videoThumbnailProvider(first));
    expect(modified, isNot(first));
    expect(
      videoThumbnailProvider(modified),
      isNot(videoThumbnailProvider(first)),
    );
  });

  test('cancels a queued thumbnail when its card is disposed', () async {
    final repository = _FakeThumbnailRepository();
    final scheduler = ThumbnailJobScheduler(repository)..setScrolling(true);
    final request = scheduler.getThumbnail(_video('video.mp4'));

    request.cancel();

    expect(await request.result, isNull);
    expect(repository.generatedPaths, isEmpty);
  });

  test(
    'keeps shared work until every thumbnail consumer is disposed',
    () async {
      final scheduler = ThumbnailJobScheduler(_FakeThumbnailRepository())
        ..setScrolling(true);
      final item = _video('shared.mp4');
      final first = scheduler.getThumbnail(item);
      final second = scheduler.getThumbnail(item);

      first.cancel();
      var completed = false;
      first.result.whenComplete(() => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      second.cancel();
      expect(await first.result, isNull);
    },
  );

  test('bounds queued thumbnail work during long fast scrolls', () async {
    final scheduler = ThumbnailJobScheduler(_FakeThumbnailRepository())
      ..setScrolling(true);
    final requests = [
      for (var index = 0; index <= 40; index++)
        scheduler.getThumbnail(_video('video-$index.mp4')),
    ];

    expect(await requests.first.result, isNull);
    for (final request in requests.skip(1)) {
      request.cancel();
    }
  });

  testWidgets('retries a visible video thumbnail after queue eviction', (
    tester,
  ) async {
    final repository = _FakeThumbnailRepository();
    final scheduler = ThumbnailJobScheduler(repository)..setScrolling(true);
    final container = ProviderContainer(
      overrides: [thumbnailJobSchedulerProvider.overrideWithValue(scheduler)],
    );
    addTearDown(container.dispose);
    final items = [
      for (var index = 0; index <= 40; index++) _video('video-$index.mp4'),
    ];
    final subscriptions = [
      for (final item in items)
        container.listen(videoThumbnailProvider(item), (_, _) {}),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });

    await tester.pump(const Duration(milliseconds: 130));
    scheduler.resumeImmediately();
    for (var frame = 0; frame < 50; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    final firstThumbnail = container.read(videoThumbnailProvider(items.first));
    expect(firstThumbnail.hasValue, isTrue);
    expect(firstThumbnail.requireValue, '${items.first.path}.jpg');
  });

  testWidgets(
    'restores a disposed thumbnail synchronously from the resolved path cache',
    (tester) async {
      final repository = _FakeThumbnailRepository();
      final scheduler = ThumbnailJobScheduler(repository);
      final firstContainer = ProviderContainer(
        overrides: [thumbnailJobSchedulerProvider.overrideWithValue(scheduler)],
      );
      final item = _video('cached.mp4');
      final firstSubscription = firstContainer.listen(
        videoThumbnailProvider(item),
        (_, _) {},
      );

      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(firstSubscription.read().requireValue, '${item.path}.jpg');
      firstSubscription.close();
      firstContainer.dispose();

      final equivalentItem = _video('cached.mp4');
      final secondContainer = ProviderContainer(
        overrides: [thumbnailJobSchedulerProvider.overrideWithValue(scheduler)],
      );
      final secondSubscription = secondContainer.listen(
        videoThumbnailProvider(equivalentItem),
        (_, _) {},
      );

      final restoredThumbnail = secondSubscription.read();
      expect(restoredThumbnail.hasValue, isTrue);
      expect(restoredThumbnail.requireValue, '${item.path}.jpg');
      expect(repository.generatedPaths, [item.path]);
      secondSubscription.close();
      secondContainer.dispose();
    },
  );
}

MediaItem _video(String name) => MediaItem(
  path: '/gallery/$name',
  name: name,
  modifiedAt: DateTime(2026),
  mediaType: GalleryItemType.video,
);

final class _FakeThumbnailRepository implements ThumbnailRepository {
  final generatedPaths = <String>[];

  @override
  Future<String?> findCachedThumbnail(MediaItem item) async => null;

  @override
  Future<String?> getThumbnail(MediaItem item) async {
    generatedPaths.add(item.path);
    return '${item.path}.jpg';
  }

  @override
  Future<void> removeCachedThumbnail(MediaItem item) async {}
}
