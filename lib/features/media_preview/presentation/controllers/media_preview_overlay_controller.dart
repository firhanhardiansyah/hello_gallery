import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/media_preview_timing.dart';
import '../states/media_preview_ui_state.dart';

final class MediaPreviewOverlayController extends ChangeNotifier {
  MediaPreviewOverlayController({
    required MediaPreviewUiState Function() readPreviewState,
    ValueChanged<bool>? onVisibilityChanged,
    Duration autoHideDuration = MediaPreviewTiming.controlsAutoHide,
  }) : _readPreviewState = readPreviewState,
       _onVisibilityChanged = onVisibilityChanged,
       _autoHideDuration = autoHideDuration;

  final MediaPreviewUiState Function() _readPreviewState;
  final ValueChanged<bool>? _onVisibilityChanged;
  final Duration _autoHideDuration;

  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _controlsHovered = false;
  bool _controlsHiddenByNavigation = false;
  bool _filmstripEnabled = true;
  bool _cleanPreviewEnabled = false;
  bool _controlsVisibleBeforeCleanPreview = true;
  int _hiddenManualNavigationCount = 0;
  int _silentNavigationCount = 0;
  bool _disposed = false;

  bool get controlsVisible => _controlsVisible;
  bool get filmstripEnabled => _filmstripEnabled;
  bool get cleanPreviewEnabled => _cleanPreviewEnabled;
  bool get isManualNavigationRunning => _hiddenManualNavigationCount > 0;
  bool get isNavigationEventSuppressed => _silentNavigationCount > 0;

  void showControls({bool restartTimer = true, bool userInitiated = false}) {
    if (_cleanPreviewEnabled) return;
    if (_controlsHiddenByNavigation && !userInitiated) return;
    if (userInitiated) _controlsHiddenByNavigation = false;
    _hideTimer?.cancel();
    _setControlsVisible(true);
    if (!restartTimer) return;
    final state = _readPreviewState();
    if (!state.isPlaying || state.activeItem?.isVideo != true) return;
    scheduleAutoHide();
  }

  void scheduleAutoHide() {
    _hideTimer?.cancel();
    if (_cleanPreviewEnabled || !_controlsVisible || _controlsHovered) return;
    final state = _readPreviewState();
    if (!state.isPlaying || state.activeItem?.isVideo != true) return;
    _hideTimer = Timer(_autoHideDuration, () {
      if (_disposed) return;
      final latest = _readPreviewState();
      if (_controlsVisible &&
          !_controlsHovered &&
          latest.isPlaying &&
          latest.activeItem?.isVideo == true) {
        _setControlsVisible(false);
      }
    });
  }

  void setControlsHovered(bool hovered) {
    if (_controlsHovered == hovered) return;
    _controlsHovered = hovered;
    if (hovered) {
      _hideTimer?.cancel();
      return;
    }
    scheduleAutoHide();
  }

  void hideAfterPointerExit() {
    _hideTimer?.cancel();
    _setControlsVisible(false);
  }

  void scheduleGamepadAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDuration, () {
      if (!_disposed) _setControlsVisible(false);
    });
  }

  void setCleanPreviewEnabled(bool enabled) {
    if (_cleanPreviewEnabled == enabled) return;
    _cleanPreviewEnabled = enabled;
    _hideTimer?.cancel();
    if (enabled) {
      _controlsVisibleBeforeCleanPreview = _controlsVisible;
      _setControlsVisible(false);
      return;
    }
    _setControlsVisible(_controlsVisibleBeforeCleanPreview);
    scheduleAutoHide();
  }

  bool toggleFilmstrip() {
    _filmstripEnabled = !_filmstripEnabled;
    notifyListeners();
    return _filmstripEnabled;
  }

  Future<void> navigateWithoutControls(Future<void> Function() navigate) async {
    _hiddenManualNavigationCount++;
    suppressControlsDuringNavigation();
    try {
      await navigate();
    } finally {
      _hiddenManualNavigationCount--;
    }
  }

  void suppressControlsDuringNavigation() {
    _controlsHiddenByNavigation = true;
    _hideTimer?.cancel();
    _setControlsVisible(false);
    _silentNavigationCount++;
    unawaited(_releaseNavigationEventSuppression());
  }

  Future<void> _releaseNavigationEventSuppression() async {
    await Future<void>.delayed(MediaPreviewTiming.navigationEventSuppression);
    if (_silentNavigationCount > 0) _silentNavigationCount--;
  }

  void _setControlsVisible(bool visible) {
    if (_controlsVisible != visible) {
      _controlsVisible = visible;
      notifyListeners();
    }
    _onVisibilityChanged?.call(visible);
  }

  @override
  void dispose() {
    _disposed = true;
    _hideTimer?.cancel();
    super.dispose();
  }
}
