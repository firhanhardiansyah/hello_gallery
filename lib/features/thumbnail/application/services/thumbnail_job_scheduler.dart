import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../domain/repositories/thumbnail_repository.dart';

final class ThumbnailJobScheduler {
  ThumbnailJobScheduler(this._repository);

  final ThumbnailRepository _repository;
  final Queue<_ThumbnailJob> _queue = Queue();
  final Map<String, Future<String?>> _pending = {};
  Timer? _resumeTimer;
  int _activeJobs = 0;
  bool _isScrolling = false;

  int get _maximumConcurrentJobs => Platform.isWindows ? 2 : 1;

  Future<String?> findCachedThumbnail(MediaItem item) {
    return _repository.findCachedThumbnail(item);
  }

  Future<String?> getThumbnail(MediaItem item) {
    if (!item.isVideo) return Future.value();
    return _pending.putIfAbsent(item.path, () {
      final completer = Completer<String?>();
      _queue.add(_ThumbnailJob(item, completer));
      _processPendingJobs();
      return completer.future;
    });
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

  void _processPendingJobs() {
    if (_isScrolling) return;
    while (_activeJobs < _maximumConcurrentJobs && _queue.isNotEmpty) {
      final job = _queue.removeLast();
      _activeJobs++;
      unawaited(
        _processJob(job).whenComplete(() {
          _activeJobs--;
          _pending.remove(job.item.path);
          _processPendingJobs();
        }),
      );
    }
  }

  Future<void> _processJob(_ThumbnailJob job) async {
    try {
      await SchedulerBinding.instance.endOfFrame;
      job.completer.complete(await _repository.getThumbnail(job.item));
    } catch (error, stackTrace) {
      debugPrint('Could not create thumbnail for ${job.item.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
      job.completer.complete(null);
    }
  }
}

final class _ThumbnailJob {
  const _ThumbnailJob(this.item, this.completer);

  final MediaItem item;
  final Completer<String?> completer;
}
