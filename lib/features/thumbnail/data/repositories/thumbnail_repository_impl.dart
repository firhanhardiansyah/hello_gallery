import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import '../../domain/repositories/thumbnail_repository.dart';

final class ThumbnailRepositoryImpl implements ThumbnailRepository {
  static const _platformThumbnailChannel = MethodChannel(
    'hello_gallery/platform_thumbnail',
  );
  Future<Directory>? _cacheDirectory;

  @override
  Future<String?> findCachedThumbnail(MediaItem item) async {
    final thumbnail = await _thumbnailFile(_cacheKey(item));
    return await thumbnail.exists() ? thumbnail.path : null;
  }

  @override
  Future<String?> getThumbnail(MediaItem item) async {
    if (!item.isVideo) return null;
    final key = _cacheKey(item);
    final thumbnail = await _thumbnailFile(key);
    final cacheDirectory = thumbnail.parent;
    if (await thumbnail.exists()) return thumbnail.path;

    if (Platform.isWindows || Platform.isMacOS) {
      try {
        final bytes = await _platformThumbnailChannel.invokeMethod<Uint8List>(
          'getThumbnail',
          {'path': item.path, 'size': 256},
        );
        if (bytes != null && bytes.isNotEmpty) {
          await cacheDirectory.create(recursive: true);
          await thumbnail.writeAsBytes(bytes, flush: false);
          return thumbnail.path;
        }
      } on PlatformException catch (error) {
        debugPrint('Native platform thumbnail failed: $error');
      }
    }

    final player = Player(
      configuration: const PlayerConfiguration(muted: true),
    );
    try {
      final videoController = VideoController(
        player,
        configuration: const VideoControllerConfiguration(width: 320),
      );
      await videoController.platform.future.timeout(const Duration(seconds: 5));
      final videoReady = player.stream.width.firstWhere(
        (width) => width != null && width > 0,
      );
      await player.open(Media(item.path), play: false);
      await videoReady.timeout(const Duration(seconds: 5));
      final duration = player.state.duration;
      final tenPercent = Duration(
        microseconds: (duration.inMicroseconds * 0.1).round(),
      );
      final position = tenPercent < const Duration(seconds: 1)
          ? const Duration(seconds: 1)
          : tenPercent > const Duration(seconds: 30)
          ? const Duration(seconds: 30)
          : tenPercent;
      await player.seek(position < duration ? position : Duration.zero);
      final bytes = await player.screenshot(
        format: 'image/jpeg',
        includeLibassSubtitles: false,
      );
      if (bytes == null || bytes.isEmpty) return null;
      await cacheDirectory.create(recursive: true);
      await thumbnail.writeAsBytes(bytes, flush: false);
      return thumbnail.path;
    } finally {
      await player.dispose();
    }
  }

  @override
  Future<void> removeCachedThumbnail(MediaItem item) async {
    final thumbnail = await _thumbnailFile(_cacheKey(item));
    if (await thumbnail.exists()) await thumbnail.delete();
  }

  Future<File> _thumbnailFile(String key) async {
    final cacheRoot = await (_cacheDirectory ??=
        getApplicationCacheDirectory());
    return File(path.join(cacheRoot.path, 'video_thumbnails', '$key.jpg'));
  }

  String _cacheKey(MediaItem item) {
    final generator = Platform.isWindows
        ? 'windows-shell-v1'
        : Platform.isMacOS
        ? 'macos-quick-look-v1'
        : 'media-kit-v1';
    final source =
        '$generator\u0000${item.path}\u0000${item.sizeBytes}\u0000${item.modifiedAt.microsecondsSinceEpoch}';
    var hash = 0xcbf29ce484222325;
    for (final byte in source.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
