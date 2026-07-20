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

  final ThumbnailRepository _repository;
  final Queue<_ThumbnailJob> _queue = Queue();
  final Map<String, _ThumbnailJob> _pending = {};
  Timer? _resumeTimer;
  int _activeJobs = 0;
  bool _isScrolling = false;

  int get _maximumConcurrentJobs => Platform.isWindows ? 2 : 1;

  Future<String?> findCachedThumbnail(MediaItem item) {
    return _repository.findCachedThumbnail(item);
  }

  ThumbnailRequest getThumbnail(MediaItem item) {
    if (!item.isVideo) {
      return ThumbnailRequest._(
        Future.value(),
        () {},
        isCancelled: () => false,
      );
    }
    final job = _pending.putIfAbsent(item.path, () {
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
          if (identical(_pending[job.item.path], job)) {
            _pending.remove(job.item.path);
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
    if (identical(_pending[job.item.path], job)) {
      _pending.remove(job.item.path);
    }
    if (!job.completer.isCompleted) job.completer.complete(null);
  }
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
