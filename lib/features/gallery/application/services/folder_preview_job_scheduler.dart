import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as path;

import '../../domain/entities/gallery_item.dart';
import '../use_cases/find_folder_preview_media.dart';
import 'folder_preview_cache.dart';

final class FolderPreviewJobScheduler {
  FolderPreviewJobScheduler(this._findPreviews, this._cache);

  static const _maximumConcurrentJobs = 2;
  static const _maximumQueuedJobs = 24;

  final FindFolderPreviewMedia _findPreviews;
  final FolderPreviewCache _cache;
  final Queue<_FolderPreviewJob> _queue = Queue();
  final Map<String, _FolderPreviewJob> _pending = {};
  Timer? _resumeTimer;
  int _activeJobs = 0;
  bool _isScrolling = false;

  FolderPreviewRequest getPreview(GalleryFolder folder) {
    final key = path.normalize(folder.path);
    final cached = _cache.get(key);
    if (cached != null) {
      return FolderPreviewRequest._(
        Future.value(cached),
        () {},
        isCancelled: () => false,
      );
    }

    var job = _pending[key];
    if (job == null) {
      job = _FolderPreviewJob(folder);
      _pending[key] = job;
      _queue.add(job);
      _trimQueue();
      _processPendingJobs();
    }
    final retainedJob = job;
    retainedJob.retainers++;
    var released = false;
    return FolderPreviewRequest._(retainedJob.completer.future, () {
      if (released) return;
      released = true;
      retainedJob.retainers--;
      if (retainedJob.retainers == 0) _cancel(retainedJob);
    }, isCancelled: () => retainedJob.cancelled);
  }

  void invalidate(String folderPath) {
    final key = path.normalize(folderPath);
    _cache.invalidate(key);
    final job = _pending[key];
    if (job != null) _cancel(job);
  }

  void clear() {
    _cache.clear();
    for (final job in [..._pending.values]) {
      _cancel(job);
    }
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
      if (job.cancelled) continue;
      job.active = true;
      _activeJobs++;
      unawaited(
        _processJob(job).whenComplete(() {
          _activeJobs--;
          final key = path.normalize(job.folder.path);
          if (identical(_pending[key], job)) _pending.remove(key);
          _processPendingJobs();
        }),
      );
    }
  }

  Future<void> _processJob(_FolderPreviewJob job) async {
    try {
      await SchedulerBinding.instance.endOfFrame;
      final previews = await _findPreviews(
        job.folder.path,
        isCancelled: () => job.cancelled,
      );
      if (!job.cancelled) {
        _cache.put(job.folder.path, previews);
      }
      if (!job.completer.isCompleted) {
        job.completer.complete(job.cancelled ? const [] : previews);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Could not find previews for ${job.folder.path}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!job.completer.isCompleted) job.completer.complete(const []);
    }
  }

  void _trimQueue() {
    while (_queue.length > _maximumQueuedJobs) {
      _cancel(_queue.first);
    }
  }

  void _cancel(_FolderPreviewJob job) {
    if (job.cancelled) return;
    job.cancelled = true;
    if (!job.active) _queue.remove(job);
    final key = path.normalize(job.folder.path);
    if (identical(_pending[key], job)) _pending.remove(key);
    if (!job.completer.isCompleted) job.completer.complete(const []);
  }
}

final class _FolderPreviewJob {
  _FolderPreviewJob(this.folder);

  final GalleryFolder folder;
  final completer = Completer<List<MediaItem>>();
  int retainers = 0;
  bool active = false;
  bool cancelled = false;
}

final class FolderPreviewRequest {
  const FolderPreviewRequest._(
    this.result,
    this.cancel, {
    required bool Function() isCancelled,
  }) : _isCancelled = isCancelled;

  final Future<List<MediaItem>> result;
  final VoidCallback cancel;
  final bool Function() _isCancelled;

  bool get wasCancelled => _isCancelled();
}
