import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../constants/media_preview_timing.dart';

final class MediaPreviewFilmstripController {
  static const thumbnailWidth = 88.0;
  static const thumbnailHeight = 64.0;
  static const itemSpacing = 4.0;
  static const itemExtent = thumbnailWidth + itemSpacing;
  static const horizontalPadding = 16.0;

  final scrollController = ScrollController();

  int? _lastRevealedIndex;
  int? _pendingIndex;
  bool _pendingAnimated = true;
  bool _revealScheduled = false;

  void reveal(int index, {bool animated = true, bool force = false}) {
    if (!force && _lastRevealedIndex == index) return;
    _lastRevealedIndex = index;
    _pendingIndex = index;
    _pendingAnimated = animated;
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      final pendingIndex = _pendingIndex;
      final pendingAnimated = _pendingAnimated;
      _pendingIndex = null;
      if (pendingIndex == null || !scrollController.hasClients) {
        _lastRevealedIndex = null;
        return;
      }
      _revealNow(pendingIndex, animated: pendingAnimated);
    });
  }

  void handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !scrollController.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      _handleResolvedPointerSignal,
    );
  }

  void dispose() => scrollController.dispose();

  void _revealNow(int index, {required bool animated}) {
    final position = scrollController.position;
    final itemCenter =
        horizontalPadding + (index * itemExtent) + (thumbnailWidth / 2);
    final target = (itemCenter - (position.viewportDimension / 2)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 1) return;
    if (!animated) {
      scrollController.jumpTo(target);
      return;
    }
    scrollController.animateTo(
      target,
      duration: MediaPreviewTiming.overlayTransition,
      curve: Curves.easeOut,
    );
  }

  void _handleResolvedPointerSignal(PointerEvent event) {
    if (event is! PointerScrollEvent || !scrollController.hasClients) return;
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta != 0) scrollController.position.pointerScroll(delta);
    event.respond(allowPlatformDefault: false);
  }
}
