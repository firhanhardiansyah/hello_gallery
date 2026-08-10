import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/media_preview/data/repositories/platform_seek_preview_frame_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('caches coarse and precise frames independently', () async {
    const channel = MethodChannel(
      PlatformSeekPreviewFrameRepository.channelName,
    );
    final calls = <MethodCall>[];
    final frameBytes = Uint8List.fromList([1, 2, 3]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return frameBytes;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final cacheDirectory = await Directory.systemTemp.createTemp(
      'seek-preview-cache-test',
    );
    addTearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (await cacheDirectory.exists()) {
        await cacheDirectory.delete(recursive: true);
      }
    });
    final repository = PlatformSeekPreviewFrameRepository(
      channel: channel,
      getCacheDirectory: () async => cacheDirectory,
    );
    final item = MediaItem(
      path: '/gallery/video.mp4',
      name: 'video.mp4',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.video,
      sizeBytes: 42,
    );

    final first = await repository.getFrame(item, const Duration(seconds: 15));
    final second = await repository.getFrame(item, const Duration(seconds: 15));
    final precise = await repository.getFrame(
      item,
      const Duration(seconds: 15),
      precise: true,
    );

    expect(first, frameBytes);
    expect(second, frameBytes);
    expect(precise, frameBytes);
    expect(calls, hasLength(2));
    expect(calls.first.method, 'getFrame');
    expect(calls.first.arguments, {
      'path': item.path,
      'timestampMs': 15000,
      'size': 240,
      'precise': false,
    });
    expect(calls.last.arguments, {
      'path': item.path,
      'timestampMs': 15000,
      'size': 240,
      'precise': true,
    });
  });
}
