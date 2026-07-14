import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../shared/models/gallery_item.dart';

final videoThumbnailServiceProvider = Provider(
  (ref) => VideoThumbnailService(),
);

final videoThumbnailProvider = FutureProvider.autoDispose
    .family<String?, MediaItem>(
      (ref, item) => ref.read(videoThumbnailServiceProvider).thumbnailFor(item),
    );

class VideoThumbnailService {
  Future<void> _queue = Future.value();
  final Map<String, Future<String?>> _pending = {};

  Future<String?> thumbnailFor(MediaItem item) {
    if (!item.isVideo) return Future.value();
    final key = _cacheKey(item);
    return _pending.putIfAbsent(key, () {
      final completer = Completer<String?>();
      _queue = _queue.catchError((_) {}).then((_) async {
        try {
          completer.complete(await _loadOrCreate(item, key));
        } catch (error, stackTrace) {
          debugPrint('Could not create thumbnail for ${item.path}: $error');
          debugPrintStack(stackTrace: stackTrace);
          completer.complete(null);
        } finally {
          _pending.remove(key);
        }
      });
      return completer.future;
    });
  }

  Future<String?> _loadOrCreate(MediaItem item, String key) async {
    final cacheRoot = await getApplicationCacheDirectory();
    final cacheDirectory = Directory(
      path.join(cacheRoot.path, 'video_thumbnails'),
    );
    final thumbnail = File(path.join(cacheDirectory.path, '$key.jpg'));
    if (await thumbnail.exists()) return thumbnail.path;

    final player = Player(
      configuration: const PlayerConfiguration(muted: true),
    );
    try {
      final videoController = VideoController(
        player,
        configuration: const VideoControllerConfiguration(width: 420),
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

  String _cacheKey(MediaItem item) {
    final source =
        '${item.path}\u0000${item.sizeBytes}\u0000${item.modifiedAt.microsecondsSinceEpoch}';
    var hash = 0xcbf29ce484222325;
    for (final byte in source.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
