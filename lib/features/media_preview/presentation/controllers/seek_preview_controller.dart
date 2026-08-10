import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SeekPreviewFrameLoader =
    Future<Uint8List?> Function(Duration position, {bool precise});

final class SeekPreviewController extends ChangeNotifier {
  SeekPreviewController({
    required SeekPreviewFrameLoader loadFrame,
    required Duration debounceDuration,
    Duration exactDelay = const Duration(milliseconds: 350),
    Duration prefetchDelay = const Duration(milliseconds: 750),
  }) : _loadFrame = loadFrame,
       _debounceDuration = debounceDuration,
       _exactDelay = exactDelay,
       _prefetchDelay = prefetchDelay;

  final SeekPreviewFrameLoader _loadFrame;
  final Duration _debounceDuration;
  final Duration _exactDelay;
  final Duration _prefetchDelay;

  Timer? _debounceTimer;
  Timer? _exactTimer;
  Timer? _prefetchTimer;
  Uint8List? _frameBytes;
  Duration? _requestedBucket;
  Duration _lastTotalDuration = Duration.zero;
  bool _loading = false;
  bool _coarseRequestInFlight = false;
  bool _coarseRequestQueued = false;
  int _requestGeneration = 0;
  int? _exactFrameGeneration;
  bool _disposed = false;

  Uint8List? get frameBytes => _frameBytes;
  bool get isLoading => _loading;

  void request(Duration position, Duration totalDuration) {
    _lastTotalDuration = totalDuration;
    final exactPosition = _clampPosition(position, totalDuration);
    final bucket = bucketFor(exactPosition, totalDuration);
    final generation = ++_requestGeneration;
    final bucketChanged = bucket != _requestedBucket;

    _requestedBucket = bucket;
    _exactFrameGeneration = null;
    _exactTimer?.cancel();
    _prefetchTimer?.cancel();

    if (bucketChanged || _frameBytes == null || _loading) {
      final shouldNotify = !_loading;
      _loading = true;
      if (shouldNotify) notifyListeners();
      _scheduleCoarseLoad(bucket, generation);
    } else {
      _debounceTimer?.cancel();
    }

    _exactTimer = Timer(
      _exactDelay,
      () => _loadExact(exactPosition, bucket, generation),
    );
  }

  void cancelPending() {
    _debounceTimer?.cancel();
    _exactTimer?.cancel();
    _prefetchTimer?.cancel();
    _coarseRequestQueued = false;
    _requestGeneration++;
    if (_loading) {
      _loading = false;
      notifyListeners();
    }
  }

  Duration bucketFor(Duration position, Duration totalDuration) {
    final interval = intervalFor(totalDuration);
    final bucketMilliseconds =
        (position.inMilliseconds ~/ interval.inMilliseconds) *
        interval.inMilliseconds;
    final maximum = totalDuration > Duration.zero
        ? totalDuration - const Duration(milliseconds: 1)
        : Duration.zero;
    return Duration(
      milliseconds: bucketMilliseconds,
    ).clamp(Duration.zero, maximum);
  }

  Duration intervalFor(Duration totalDuration) => switch (totalDuration) {
    <= const Duration(minutes: 10) => const Duration(seconds: 5),
    <= const Duration(hours: 1) => const Duration(seconds: 10),
    _ => const Duration(seconds: 20),
  };

  Future<void> _loadCoarse(Duration bucket, int generation) async {
    if (_coarseRequestInFlight) {
      _coarseRequestQueued = true;
      return;
    }
    _coarseRequestInFlight = true;
    final frameBytes = await _loadFrame(bucket, precise: false);
    _coarseRequestInFlight = false;
    if (_disposed) return;

    if (generation == _requestGeneration &&
        _exactFrameGeneration != generation) {
      if (frameBytes != null) _frameBytes = frameBytes;
      _loading = false;
      notifyListeners();
    }

    if (_coarseRequestQueued) {
      _coarseRequestQueued = false;
      final latestBucket = _requestedBucket;
      if (latestBucket != null) {
        unawaited(_loadCoarse(latestBucket, _requestGeneration));
      }
    }
  }

  Future<void> _loadExact(
    Duration position,
    Duration bucket,
    int generation,
  ) async {
    final frameBytes = await _loadFrame(position, precise: true);
    if (_disposed || generation != _requestGeneration) return;

    if (frameBytes != null) {
      _frameBytes = frameBytes;
      _exactFrameGeneration = generation;
    }
    _loading = false;
    notifyListeners();
    _scheduleAdjacentPrefetch(bucket, generation);
  }

  void _scheduleCoarseLoad(Duration bucket, int generation) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      _debounceDuration,
      () => _loadCoarse(bucket, generation),
    );
  }

  void _scheduleAdjacentPrefetch(Duration bucket, int generation) {
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer(_prefetchDelay, () async {
      if (_disposed || generation != _requestGeneration) return;
      final interval = intervalFor(_lastTotalDuration);
      final candidates = [bucket + interval, bucket - interval];
      for (final candidate in candidates) {
        if (_disposed || generation != _requestGeneration) return;
        if (candidate < Duration.zero || candidate >= _lastTotalDuration) {
          continue;
        }
        await _loadFrame(candidate, precise: false);
      }
    });
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
    _debounceTimer?.cancel();
    _exactTimer?.cancel();
    _prefetchTimer?.cancel();
    super.dispose();
  }
}

extension on Duration {
  Duration clamp(Duration minimum, Duration maximum) {
    if (this < minimum) return minimum;
    if (this > maximum) return maximum;
    return this;
  }
}
