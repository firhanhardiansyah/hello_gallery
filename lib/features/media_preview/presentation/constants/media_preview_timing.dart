abstract final class MediaPreviewTiming {
  // Visibility behavior.
  static const controlsAutoHide = Duration(seconds: 3);
  static const playbackFeedback = Duration(milliseconds: 250);
  static const navigationEventSuppression = Duration(milliseconds: 500);

  // Motion.
  static const quickFade = Duration(milliseconds: 120);
  static const overlayFade = Duration(milliseconds: 150);
  static const overlayTransition = Duration(milliseconds: 180);

  // Input behavior.
  static const scrollNavigationReset = Duration(milliseconds: 180);
  static const seekBackwardStep = Duration(seconds: -3);
  static const seekForwardStep = Duration(seconds: 3);
}
