import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SeekPreviewFrameLoader = Future<Uint8List?> Function(Duration position);

final class SeekPreviewController extends ChangeNotifier {
  SeekPreviewController({
    required SeekPreviewFrameLoader loadFrame,
    required Duration debounceDuration,
    Duration prefetchDelay = const Duration(milliseconds: 750),
  }) : _loadFrame = loadFrame,
       _debounceDuration = debounceDuration,
       _prefetchDelay = prefetchDelay;

  final SeekPreviewFrameLoader _loadFrame;
  final Duration _debounceDuration;
  final Duration _prefetchDelay;

  Timer? _debounceTimer;
  Timer? _prefetchTimer;
  Uint8List? _frameBytes;
  Duration? _requestedBucket;
  Duration _lastTotalDuration = Duration.zero;
  bool _loading = false;
  bool _requestInFlight = false;
  int _requestGeneration = 0;
  bool _disposed = false;

  Uint8List? get frameBytes => _frameBytes;
  bool get isLoading => _loading;

  void request(Duration position, Duration totalDuration) {
    _lastTotalDuration = totalDuration;
    final bucket = bucketFor(position, totalDuration);
    if (bucket == _requestedBucket && _frameBytes != null) return;
    if (bucket == _requestedBucket && _loading) {
      if (_debounceTimer?.isActive ?? false) {
        _scheduleLoad(bucket, ++_requestGeneration);
      }
      return;
    }
    _requestedBucket = bucket;
    _loading = true;
    _prefetchTimer?.cancel();
    final generation = ++_requestGeneration;
    notifyListeners();
    _scheduleLoad(bucket, generation);
  }

  void cancelPending() {
    _debounceTimer?.cancel();
    _prefetchTimer?.cancel();
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

  Future<void> _load(Duration bucket, int generation) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    final frameBytes = await _loadFrame(bucket);
    _requestInFlight = false;
    if (_disposed) return;
    if (generation == _requestGeneration) {
      _frameBytes = frameBytes;
      _loading = false;
      notifyListeners();
      _scheduleAdjacentPrefetch(bucket, generation);
      return;
    }
    final latestBucket = _requestedBucket;
    if (_loading && latestBucket != null) {
      unawaited(_load(latestBucket, _requestGeneration));
    }
  }

  void _scheduleLoad(Duration bucket, int generation) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () => _load(bucket, generation));
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
        await _loadFrame(candidate);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
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
