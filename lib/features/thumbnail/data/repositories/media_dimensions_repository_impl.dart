import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:image/image.dart' as image;

import '../../domain/repositories/media_dimensions_repository.dart';
import '../../domain/value_objects/media_dimensions.dart';

typedef MediaDimensionsReader = Future<MediaDimensions?> Function(String path);

final class MediaDimensionsRepositoryImpl implements MediaDimensionsRepository {
  MediaDimensionsRepositoryImpl({MediaDimensionsReader? reader})
    : _reader = reader ?? _readDimensionsInBackground;

  static const _maximumConcurrentReads = 2;
  static const _maximumQueuedReads = 48;
  static const _maximumCachedDimensions = 4096;

  final MediaDimensionsReader _reader;
  final Queue<_DimensionsJob> _queue = Queue();
  final Map<String, _DimensionsJob> _pending = {};
  final LinkedHashMap<String, MediaDimensions> _cache = LinkedHashMap();
  int _activeReads = 0;

  @override
  Future<MediaDimensions?> getDimensions(
    MediaItem item, {
    String? videoThumbnailPath,
  }) {
    final sourcePath = item.isVideo ? videoThumbnailPath : item.path;
    if (sourcePath == null) return Future.value();
    final key = _cacheKey(item);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return Future.value(cached);
    }
    final pending = _pending[key];
    if (pending != null) return pending.completer.future;

    final job = _DimensionsJob(key: key, sourcePath: sourcePath);
    _pending[key] = job;
    _queue.add(job);
    _trimQueue();
    _processQueue();
    return job.completer.future;
  }

  void _processQueue() {
    while (_activeReads < _maximumConcurrentReads && _queue.isNotEmpty) {
      final job = _queue.removeLast();
      _activeReads++;
      unawaited(
        _read(job).whenComplete(() {
          _activeReads--;
          if (identical(_pending[job.key], job)) _pending.remove(job.key);
          _processQueue();
        }),
      );
    }
  }

  Future<void> _read(_DimensionsJob job) async {
    try {
      final dimensions = await _reader(job.sourcePath);
      if (dimensions != null) _remember(job.key, dimensions);
      if (!job.completer.isCompleted) job.completer.complete(dimensions);
    } catch (error, stackTrace) {
      debugPrint(
        'Could not read media dimensions for ${job.sourcePath}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!job.completer.isCompleted) job.completer.complete(null);
    }
  }

  void _trimQueue() {
    while (_queue.length > _maximumQueuedReads) {
      final removed = _queue.removeFirst();
      if (identical(_pending[removed.key], removed)) {
        _pending.remove(removed.key);
      }
      if (!removed.completer.isCompleted) removed.completer.complete(null);
    }
  }

  void _remember(String key, MediaDimensions dimensions) {
    _cache.remove(key);
    _cache[key] = dimensions;
    while (_cache.length > _maximumCachedDimensions) {
      _cache.remove(_cache.keys.first);
    }
  }

  String _cacheKey(MediaItem item) =>
      '${item.path}\u0000${item.sizeBytes}\u0000'
      '${item.modifiedAt.microsecondsSinceEpoch}';
}

final class _DimensionsJob {
  _DimensionsJob({required this.key, required this.sourcePath});

  final String key;
  final String sourcePath;
  final completer = Completer<MediaDimensions?>();
}

Future<MediaDimensions?> _readDimensionsInBackground(String path) =>
    compute(_readDimensions, path);

Future<MediaDimensions?> _readDimensions(String path) async {
  const maximumHeaderBytes = 4 * 1024 * 1024;
  final file = File(path);
  final handle = await file.open();
  try {
    final length = await handle.length();
    if (length <= 0) return null;
    final bytes = await handle.read(math.min(length, maximumHeaderBytes));
    final decoder =
        image.findDecoderForNamedImage(path) ?? image.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0) return null;
    return MediaDimensions(width: info.width, height: info.height);
  } finally {
    await handle.close();
  }
}
