import 'dart:async';

import 'package:flutter/widgets.dart';

final class GalleryScrollRestorer {
  GalleryScrollRestorer({
    required ScrollController scrollController,
    required bool Function() isMounted,
    required bool Function() isPreviewActive,
  }) : _scrollController = scrollController,
       _isMounted = isMounted,
       _isPreviewActive = isPreviewActive;

  static const _retryDelay = Duration(milliseconds: 50);
  static const _maximumRestoreAttempts = 12;

  final ScrollController _scrollController;
  final bool Function() _isMounted;
  final bool Function() _isPreviewActive;
  double? _savedOffset;
  int _generation = 0;

  void captureBeforePreview() {
    _generation++;
    if (_scrollController.hasClients) {
      _savedOffset = _scrollController.offset;
    }
  }

  void restoreAfterPreview() {
    final target = _savedOffset;
    if (target == null) return;
    final generation = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restore(target, generation, attempt: 0);
    });
  }

  void dispose() => _generation++;

  void _restore(double target, int generation, {required int attempt}) {
    if (!_isMounted() || _isPreviewActive() || generation != _generation) {
      return;
    }
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final offset = target.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((position.pixels - offset).abs() > 0.5) {
        _scrollController.jumpTo(offset);
      }
      if (position.maxScrollExtent >= target ||
          attempt >= _maximumRestoreAttempts) {
        _savedOffset = null;
        return;
      }
    }
    if (attempt >= _maximumRestoreAttempts) return;
    unawaited(
      Future<void>.delayed(_retryDelay, () {
        if (!_isMounted()) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restore(target, generation, attempt: attempt + 1);
        });
      }),
    );
  }
}
