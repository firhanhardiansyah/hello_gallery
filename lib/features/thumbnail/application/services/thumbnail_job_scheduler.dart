import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../domain/repositories/thumbnail_repository.dart';

final class ThumbnailJobScheduler {
  ThumbnailJobScheduler(this._repository);

  static const _maximumQueuedJobs = 40;
  static const _maximumResolvedThumbnails = 2048;

  final ThumbnailRepository _repository;
  final Queue<_ThumbnailJob> _queue = Queue();
  final Map<String, _ThumbnailJob> _pending = {};
  final LinkedHashMap<String, String> _resolvedThumbnails = LinkedHashMap();
  Timer? _resumeTimer;
  int _activeJobs = 0;
  bool _isScrolling = false;

  int get _maximumConcurrentJobs => Platform.isWindows ? 2 : 1;

  String? findResolvedThumbnail(MediaItem item) {
    final key = _itemKey(item);
    final thumbnailPath = _resolvedThumbnails.remove(key);
    if (thumbnailPath != null) {
      _resolvedThumbnails[key] = thumbnailPath;
    }
    return thumbnailPath;
  }

  Future<String?> findCachedThumbnail(MediaItem item) async {
    final resolvedThumbnail = findResolvedThumbnail(item);
    if (resolvedThumbnail != null) return resolvedThumbnail;
    final thumbnailPath = await _repository.findCachedThumbnail(item);
    if (thumbnailPath != null) _rememberResolvedThumbnail(item, thumbnailPath);
    return thumbnailPath;
  }

  Future<void> invalidate(MediaItem item) async {
    _resolvedThumbnails.remove(_itemKey(item));
    final jobs = _pending.values
        .where((job) => job.item.path == item.path)
        .toList();
    for (final job in jobs) {
      _cancel(job);
    }
    await _repository.removeCachedThumbnail(item);
  }

  ThumbnailRequest getThumbnail(MediaItem item) {
    if (!item.isVideo) {
      return ThumbnailRequest._(
        Future.value(),
        () {},
        isCancelled: () => false,
      );
    }
    final resolvedThumbnail = findResolvedThumbnail(item);
    if (resolvedThumbnail != null) {
      return ThumbnailRequest._(
        Future.value(resolvedThumbnail),
        () {},
        isCancelled: () => false,
      );
    }
    final key = _itemKey(item);
    final job = _pending.putIfAbsent(key, () {
      final created = _ThumbnailJob(item);
      _queue.add(created);
      _trimQueue();
      _processPendingJobs();
      return created;
    });
    job.retainers++;
    var released = false;
    return ThumbnailRequest._(job.completer.future, () {
      if (released) return;
      released = true;
      job.retainers--;
      if (job.retainers == 0) _cancel(job);
    }, isCancelled: () => job.cancelled);
  }

  void setScrolling(bool value) {
    _resumeTimer?.cancel();
    if (value) {
      _isScrolling = true;
      return;
    }
    _resumeTimer = Timer(const Duration(milliseconds: 150), () {
      _isScrolling = false;
      _processPendingJobs();
    });
  }

  void resumeImmediately() {
    _resumeTimer?.cancel();
    _isScrolling = false;
    _processPendingJobs();
  }

  void _processPendingJobs() {
    if (_isScrolling) return;
    while (_activeJobs < _maximumConcurrentJobs && _queue.isNotEmpty) {
      final job = _queue.removeLast();
      if (job.cancelled) continue;
      job.active = true;
      _activeJobs++;
      unawaited(
        _processJob(job).whenComplete(() {
          _activeJobs--;
          final key = _itemKey(job.item);
          if (identical(_pending[key], job)) {
            _pending.remove(key);
          }
          _processPendingJobs();
        }),
      );
    }
  }

  Future<void> _processJob(_ThumbnailJob job) async {
    try {
      await SchedulerBinding.instance.endOfFrame;
      final thumbnail = await _repository.getThumbnail(job.item);
      if (thumbnail != null) {
        _rememberResolvedThumbnail(job.item, thumbnail);
      }
      if (!job.completer.isCompleted) {
        job.completer.complete(job.cancelled ? null : thumbnail);
      }
    } catch (error, stackTrace) {
      debugPrint('Could not create thumbnail for ${job.item.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!job.completer.isCompleted) job.completer.complete(null);
    }
  }

  void _trimQueue() {
    while (_queue.length > _maximumQueuedJobs) {
      _cancel(_queue.first);
    }
  }

  void _cancel(_ThumbnailJob job) {
    if (job.cancelled) return;
    job.cancelled = true;
    if (!job.active) _queue.remove(job);
    final key = _itemKey(job.item);
    if (identical(_pending[key], job)) {
      _pending.remove(key);
    }
    if (!job.completer.isCompleted) job.completer.complete(null);
  }

  void _rememberResolvedThumbnail(MediaItem item, String thumbnailPath) {
    final key = _itemKey(item);
    _resolvedThumbnails.remove(key);
    _resolvedThumbnails[key] = thumbnailPath;
    while (_resolvedThumbnails.length > _maximumResolvedThumbnails) {
      _resolvedThumbnails.remove(_resolvedThumbnails.keys.first);
    }
  }

  String _itemKey(MediaItem item) =>
      '${item.path}\u0000${item.sizeBytes}\u0000'
      '${item.modifiedAt.microsecondsSinceEpoch}';
}

final class _ThumbnailJob {
  _ThumbnailJob(this.item);

  final MediaItem item;
  final completer = Completer<String?>();
  int retainers = 0;
  bool active = false;
  bool cancelled = false;
}

final class ThumbnailRequest {
  const ThumbnailRequest._(
    this.result,
    this.cancel, {
    required bool Function() isCancelled,
  }) : _isCancelled = isCancelled;

  final Future<String?> result;
  final VoidCallback cancel;
  final bool Function() _isCancelled;

  bool get wasCancelled => _isCancelled();
}
