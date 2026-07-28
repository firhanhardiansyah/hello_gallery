import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../domain/repositories/media_duration_repository.dart';

final class MediaDurationJobScheduler {
  MediaDurationJobScheduler(this._repository);

  static const _maximumQueuedJobs = 40;

  final MediaDurationRepository _repository;
  final Queue<_DurationJob> _queue = Queue();
  final Map<String, _DurationJob> _pending = {};
  final Map<String, Duration> _cache = {};
  bool _jobActive = false;

  MediaDurationRequest getDuration(MediaItem item) {
    if (!item.isVideo) return MediaDurationRequest.completed();

    final cacheKey = _cacheKey(item);
    final cachedDuration = _cache[cacheKey];
    if (cachedDuration != null) {
      return MediaDurationRequest.completed(cachedDuration);
    }

    final job = _pending.putIfAbsent(cacheKey, () {
      final created = _DurationJob(item, cacheKey);
      _queue.add(created);
      _trimQueue();
      _processNextJob();
      return created;
    });
    job.retainers++;

    var released = false;
    return MediaDurationRequest._(job.completer.future, () {
      if (released) return;
      released = true;
      job.retainers--;
      if (job.retainers == 0) _cancel(job);
    });
  }

  void _processNextJob() {
    if (_jobActive) return;
    while (_queue.isNotEmpty) {
      final job = _queue.removeLast();
      if (job.cancelled) continue;
      job.active = true;
      _jobActive = true;
      unawaited(
        _processJob(job).whenComplete(() {
          _jobActive = false;
          if (identical(_pending[job.cacheKey], job)) {
            _pending.remove(job.cacheKey);
          }
          _processNextJob();
        }),
      );
      return;
    }
  }

  Future<void> _processJob(_DurationJob job) async {
    try {
      await SchedulerBinding.instance.endOfFrame;
      final duration = await _repository.readVideoDuration(job.item);
      if (!job.cancelled && duration != null) {
        _cache[job.cacheKey] = duration;
      }
      if (!job.completer.isCompleted) {
        job.completer.complete(job.cancelled ? null : duration);
      }
    } catch (error, stackTrace) {
      debugPrint('Could not read duration for ${job.item.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!job.completer.isCompleted) job.completer.complete(null);
    }
  }

  void _trimQueue() {
    while (_queue.length > _maximumQueuedJobs) {
      _cancel(_queue.first);
    }
  }

  void _cancel(_DurationJob job) {
    if (job.cancelled) return;
    job.cancelled = true;
    if (!job.active) _queue.remove(job);
    if (identical(_pending[job.cacheKey], job)) {
      _pending.remove(job.cacheKey);
    }
    if (!job.completer.isCompleted) job.completer.complete(null);
  }

  String _cacheKey(MediaItem item) =>
      '${item.path}\u0000${item.sizeBytes}\u0000'
      '${item.modifiedAt.microsecondsSinceEpoch}';
}

final class _DurationJob {
  _DurationJob(this.item, this.cacheKey);

  final MediaItem item;
  final String cacheKey;
  final completer = Completer<Duration?>();
  int retainers = 0;
  bool active = false;
  bool cancelled = false;
}

final class MediaDurationRequest {
  const MediaDurationRequest._(this.result, this.cancel);

  factory MediaDurationRequest.completed([Duration? duration]) =>
      MediaDurationRequest._(Future.value(duration), () {});

  final Future<Duration?> result;
  final VoidCallback cancel;
}
