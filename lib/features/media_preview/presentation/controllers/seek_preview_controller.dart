import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/seek_preview_frame_repository.dart';

typedef SeekPreviewFrameLoader =
    Future<SeekPreviewFrame?> Function(Duration position, {bool precise});

final class SeekPreviewController extends ChangeNotifier {
  SeekPreviewController({
    required SeekPreviewFrameLoader loadFrame,
    required Duration debounceDuration,
    Duration exactDelay = const Duration(milliseconds: 250),
    Duration prefetchDelay = const Duration(milliseconds: 750),
  }) : _loadFrame = loadFrame,
       _debounceDuration = debounceDuration,
       _exactDelay = exactDelay,
       _prefetchDelay = prefetchDelay;

  final SeekPreviewFrameLoader _loadFrame;
  final Duration _debounceDuration;
  final Duration _exactDelay;
  final Duration _prefetchDelay;

  Timer? _coarseTimer;
  Timer? _exactTimer;
  Timer? _prefetchTimer;
  SeekPreviewFrame? _frame;
  Duration? _requestedBucket;
  Duration _lastTotalDuration = Duration.zero;
  bool _loading = false;
  bool _requestInFlight = false;
  _PreviewLoad? _queuedLoad;
  final List<Duration> _prefetchQueue = [];
  int _requestGeneration = 0;
  bool _disposed = false;

  Uint8List? get frameBytes => _frame?.bytes;
  bool get isLoading => _loading;

  void request(Duration position, Duration totalDuration) {
    _lastTotalDuration = totalDuration;
    final exactPosition = _clampPosition(position, totalDuration);
    final bucket = bucketFor(exactPosition, totalDuration);
    final generation = ++_requestGeneration;
    final bucketChanged = bucket != _requestedBucket;

    _requestedBucket = bucket;
    _exactTimer?.cancel();
    _prefetchTimer?.cancel();
    _prefetchQueue.clear();

    if (bucketChanged || _frame == null) {
      if (bucketChanged) _frame = null;
      final shouldNotify = !_loading || bucketChanged;
      _loading = true;
      if (shouldNotify) notifyListeners();
      _scheduleCoarseLoad();
    }

    _exactTimer = Timer(
      _exactDelay,
      () => _enqueueLoad(
        _PreviewLoad(
          position: exactPosition,
          bucket: bucket,
          generation: generation,
          precise: true,
        ),
      ),
    );
  }

  void cancelPending() {
    _coarseTimer?.cancel();
    _exactTimer?.cancel();
    _prefetchTimer?.cancel();
    _queuedLoad = null;
    _prefetchQueue.clear();
    _requestGeneration++;
    if (_loading) {
      _loading = false;
      notifyListeners();
    }
  }

  Duration bucketFor(Duration position, Duration totalDuration) {
    final interval = intervalFor(totalDuration);
    final intervalMs = interval.inMilliseconds;
    final bucketMilliseconds =
        ((position.inMilliseconds + (intervalMs ~/ 2)) ~/ intervalMs) *
        intervalMs;
    final maximum = totalDuration > Duration.zero
        ? totalDuration - const Duration(milliseconds: 1)
        : Duration.zero;
    return Duration(
      milliseconds: bucketMilliseconds,
    ).clamp(Duration.zero, maximum);
  }

  Duration intervalFor(Duration totalDuration) => switch (totalDuration) {
    <= const Duration(minutes: 10) => const Duration(seconds: 1),
    <= const Duration(hours: 1) => const Duration(seconds: 2),
    _ => const Duration(seconds: 5),
  };

  void _scheduleCoarseLoad() {
    if (_coarseTimer?.isActive ?? false) return;
    _coarseTimer = Timer(_debounceDuration, () {
      final bucket = _requestedBucket;
      if (bucket == null || _disposed) return;
      _enqueueLoad(
        _PreviewLoad(
          position: bucket,
          bucket: bucket,
          generation: _requestGeneration,
          precise: false,
        ),
      );
    });
  }

  void _enqueueLoad(_PreviewLoad load) {
    if (_disposed || load.generation != _requestGeneration) return;
    if (_requestInFlight) {
      _queuedLoad = load;
      return;
    }
    _requestInFlight = true;
    unawaited(_runLoad(load));
  }

  Future<void> _runLoad(_PreviewLoad load) async {
    SeekPreviewFrame? frame;
    try {
      frame = await _loadFrame(load.position, precise: load.precise);
    } on Object {
      frame = null;
    }

    if (!_disposed && !load.prefetch && load.generation == _requestGeneration) {
      if (frame != null && _isTimestampAcceptable(frame, load)) {
        _frame = frame;
      }
      _loading = false;
      notifyListeners();
      if (load.precise && frame != null) {
        _scheduleAdjacentPrefetch(load.bucket, load.generation);
      }
    }

    _requestInFlight = false;
    if (_disposed) return;
    final queued = _queuedLoad;
    _queuedLoad = null;
    if (queued != null) {
      _enqueueLoad(queued);
      return;
    }
    _drainPrefetchQueue();
  }

  bool _isTimestampAcceptable(SeekPreviewFrame frame, _PreviewLoad load) {
    final difference = (frame.actualPosition - frame.requestedPosition)
        .absolute();
    final tolerance = load.precise
        ? const Duration(milliseconds: 750)
        : const Duration(milliseconds: 1000);
    return difference <= tolerance;
  }

  void _scheduleAdjacentPrefetch(Duration bucket, int generation) {
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer(_prefetchDelay, () {
      if (_disposed || generation != _requestGeneration) return;
      final interval = intervalFor(_lastTotalDuration);
      _prefetchQueue
        ..clear()
        ..addAll(
          [bucket + interval, bucket - interval].where(
            (candidate) =>
                candidate >= Duration.zero && candidate < _lastTotalDuration,
          ),
        );
      _drainPrefetchQueue();
    });
  }

  void _drainPrefetchQueue() {
    if (_requestInFlight || _queuedLoad != null || _prefetchQueue.isEmpty) {
      return;
    }
    final position = _prefetchQueue.removeAt(0);
    _enqueueLoad(
      _PreviewLoad(
        position: position,
        bucket: position,
        generation: _requestGeneration,
        precise: false,
        prefetch: true,
      ),
    );
  }

  Duration _clampPosition(Duration position, Duration totalDuration) {
    final maximum = totalDuration > Duration.zero
        ? totalDuration - const Duration(milliseconds: 1)
        : Duration.zero;
    return position.clamp(Duration.zero, maximum);
  }

  @override
  void dispose() {
    _disposed = true;
    _coarseTimer?.cancel();
    _exactTimer?.cancel();
    _prefetchTimer?.cancel();
    _queuedLoad = null;
    _prefetchQueue.clear();
    super.dispose();
  }
}

final class _PreviewLoad {
  const _PreviewLoad({
    required this.position,
    required this.bucket,
    required this.generation,
    required this.precise,
    this.prefetch = false,
  });

  final Duration position;
  final Duration bucket;
  final int generation;
  final bool precise;
  final bool prefetch;
}

extension on Duration {
  Duration clamp(Duration minimum, Duration maximum) {
    if (this < minimum) return minimum;
    if (this > maximum) return maximum;
    return this;
  }

  Duration absolute() => isNegative ? -this : this;
}
