import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/thumbnail/application/services/thumbnail_job_scheduler.dart';
import 'package:hello_gallery/features/thumbnail/domain/repositories/thumbnail_repository.dart';

void main() {
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
}
