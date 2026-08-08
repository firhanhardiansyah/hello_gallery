import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/thumbnail/data/repositories/media_dimensions_repository_impl.dart';
import 'package:hello_gallery/features/thumbnail/domain/value_objects/media_dimensions.dart';
import 'package:image/image.dart' as image;

void main() {
  test('deduplicates pending reads and reuses resolved dimensions', () async {
    final readCompleter = Completer<MediaDimensions?>();
    var readCount = 0;
    final repository = MediaDimensionsRepositoryImpl(
      reader: (_) {
        readCount++;
        return readCompleter.future;
      },
    );
    final item = MediaItem(
      path: '/gallery/photo.jpg',
      name: 'photo.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
      sizeBytes: 42,
    );

    final first = repository.getDimensions(item);
    final second = repository.getDimensions(item);
    expect(readCount, 1);

    readCompleter.complete(const MediaDimensions(width: 1920, height: 1080));
    expect(await first, const MediaDimensions(width: 1920, height: 1080));
    expect(await second, const MediaDimensions(width: 1920, height: 1080));
    expect(await repository.getDimensions(item), isNotNull);
    expect(readCount, 1);
  });

  test('uses the generated thumbnail as the video dimension source', () async {
    String? sourcePath;
    final repository = MediaDimensionsRepositoryImpl(
      reader: (path) async {
        sourcePath = path;
        return const MediaDimensions(width: 1080, height: 1920);
      },
    );
    final item = MediaItem(
      path: '/gallery/video.mp4',
      name: 'video.mp4',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.video,
    );

    final dimensions = await repository.getDimensions(
      item,
      videoThumbnailPath: '/cache/video.jpg',
    );

    expect(sourcePath, '/cache/video.jpg');
    expect(dimensions?.aspectRatio, closeTo(9 / 16, 0.0001));
  });

  test(
    'keeps native portrait orientation over a landscape thumbnail',
    () async {
      var fallbackReadCount = 0;
      final repository = MediaDimensionsRepositoryImpl(
        reader: (_) async {
          fallbackReadCount++;
          return const MediaDimensions(width: 1920, height: 1080);
        },
        videoReader: (_) async =>
            const MediaDimensions(width: 1080, height: 1920),
      );
      final item = MediaItem(
        path: '/gallery/video.mp4',
        name: 'video.mp4',
        modifiedAt: DateTime(2026),
        mediaType: GalleryItemType.video,
      );

      final dimensions = await repository.getDimensions(
        item,
        videoThumbnailPath: '/cache/video.jpg',
      );

      expect(dimensions?.aspectRatio, closeTo(9 / 16, 0.0001));
      expect(fallbackReadCount, 0);
    },
  );

  test('reads dimensions without decoding the full image in the UI', () async {
    final directory = await Directory.systemTemp.createTemp(
      'hello-gallery-dimensions-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/landscape.png');
    await file.writeAsBytes(
      image.encodePng(image.Image(width: 640, height: 320)),
    );
    final item = MediaItem(
      path: file.path,
      name: 'landscape.png',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
    );

    final dimensions = await MediaDimensionsRepositoryImpl().getDimensions(
      item,
    );

    expect(dimensions, const MediaDimensions(width: 640, height: 320));
  });

  test('applies JPEG EXIF orientation to image dimensions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'hello-gallery-oriented-dimensions-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/portrait.jpg');
    final source = image.Image(width: 640, height: 320);
    source.exif.imageIfd.orientation = 6;
    await file.writeAsBytes(image.encodeJpg(source));
    final item = MediaItem(
      path: file.path,
      name: 'portrait.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
    );

    final dimensions = await MediaDimensionsRepositoryImpl().getDimensions(
      item,
    );

    expect(dimensions, const MediaDimensions(width: 320, height: 640));
  });
}
