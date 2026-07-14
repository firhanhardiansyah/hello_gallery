import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../shared/models/gallery_item.dart';

final videoThumbnailServiceProvider = Provider(
  (ref) => VideoThumbnailService(),
);

final videoThumbnailProvider = FutureProvider.family<String?, MediaItem>(
  (ref, item) => ref.read(videoThumbnailServiceProvider).thumbnailFor(item),
);

final cachedVideoThumbnailProvider = FutureProvider.family<String?, MediaItem>(
  (ref, item) =>
      ref.read(videoThumbnailServiceProvider).cachedThumbnailFor(item),
);

class VideoThumbnailService {
  static const _platformThumbnailChannel = MethodChannel(
    'hello_gallery/platform_thumbnail',
  );

  final Queue<_ThumbnailJob> _queue = Queue();
  final Map<String, Future<String?>> _pending = {};
  Timer? _resumeTimer;
  int _activeJobs = 0;
  bool _isScrolling = false;

  int get _maximumConcurrentJobs => Platform.isWindows ? 2 : 1;

  Future<String?> cachedThumbnailFor(MediaItem item) async {
    final thumbnail = await _thumbnailFile(_cacheKey(item));
    return await thumbnail.exists() ? thumbnail.path : null;
  }

  void setScrolling(bool value) {
    _resumeTimer?.cancel();
    if (value) {
      _isScrolling = true;
      return;
    }
    _resumeTimer = Timer(const Duration(milliseconds: 150), () {
      _isScrolling = false;
      _drainQueue();
    });
  }

  Future<String?> thumbnailFor(MediaItem item) {
    if (!item.isVideo) return Future.value();
    final key = _cacheKey(item);
    return _pending.putIfAbsent(key, () {
      final completer = Completer<String?>();
      _queue.add(_ThumbnailJob(item, key, completer));
      _drainQueue();
      return completer.future;
    });
  }

  void _drainQueue() {
    if (_isScrolling) return;
    while (_activeJobs < _maximumConcurrentJobs && _queue.isNotEmpty) {
      // The newest jobs are most likely to still be visible after a scroll.
      final job = _queue.removeLast();
      _activeJobs++;
      unawaited(
        _run(job).whenComplete(() {
          _activeJobs--;
          _pending.remove(job.key);
          _drainQueue();
        }),
      );
    }
  }

  Future<void> _run(_ThumbnailJob job) async {
    try {
      job.completer.complete(await _loadOrCreate(job.item, job.key));
    } catch (error, stackTrace) {
      debugPrint('Could not create thumbnail for ${job.item.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
      job.completer.complete(null);
    }
  }

  Future<String?> _loadOrCreate(MediaItem item, String key) async {
    final thumbnail = await _thumbnailFile(key);
    final cacheDirectory = thumbnail.parent;
    if (await thumbnail.exists()) return thumbnail.path;

    // Let the grid paint its placeholders before starting native decoding.
    await SchedulerBinding.instance.endOfFrame;

    if (Platform.isWindows) {
      try {
        final bytes = await _platformThumbnailChannel.invokeMethod<Uint8List>(
          'getThumbnail',
          {'path': item.path, 'size': 320},
        );
        if (bytes != null && bytes.isNotEmpty) {
          await cacheDirectory.create(recursive: true);
          await thumbnail.writeAsBytes(bytes, flush: false);
          return thumbnail.path;
        }
      } on PlatformException catch (error) {
        debugPrint('Windows Shell thumbnail failed: $error');
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

  Future<File> _thumbnailFile(String key) async {
    final cacheRoot = await getApplicationCacheDirectory();
    return File(path.join(cacheRoot.path, 'video_thumbnails', '$key.jpg'));
  }

  String _cacheKey(MediaItem item) {
    final generator = Platform.isWindows ? 'windows-shell-v1' : 'media-kit-v1';
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

class _ThumbnailJob {
  const _ThumbnailJob(this.item, this.key, this.completer);

  final MediaItem item;
  final String key;
  final Completer<String?> completer;
}
