import 'dart:async';
import 'dart:ui';

import '../constants/media_preview_timing.dart';

final class MediaPreviewScrollInput {
  MediaPreviewScrollInput({
    this.navigationThreshold = 24,
    this.resetDelay = MediaPreviewTiming.scrollNavigationReset,
  }) : assert(navigationThreshold > 0);

  final double navigationThreshold;
  final Duration resetDelay;
  Timer? _resetTimer;
  bool _hasNavigated = false;
  double _accumulatedDelta = 0;

  int handle(Offset scrollDelta) {
    final dominantDelta = scrollDelta.dx.abs() > scrollDelta.dy.abs()
        ? scrollDelta.dx
        : scrollDelta.dy;
    if (dominantDelta == 0) return 0;

    _resetTimer?.cancel();
    _resetTimer = Timer(resetDelay, _reset);
    if (_hasNavigated) return 0;

    _accumulatedDelta += dominantDelta;
    if (_accumulatedDelta.abs() < navigationThreshold) return 0;
    final direction = _accumulatedDelta > 0 ? 1 : -1;
    _hasNavigated = true;
    _accumulatedDelta = 0;
    return direction;
  }

  void dispose() => _resetTimer?.cancel();

  void _reset() {
    _accumulatedDelta = 0;
    _hasNavigated = false;
  }
}
