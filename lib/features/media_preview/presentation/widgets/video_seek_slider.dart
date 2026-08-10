import 'package:flutter/material.dart';

import '../constants/media_preview_timing.dart';
import '../controllers/seek_preview_controller.dart';
import 'video_seek_preview_card.dart';

class VideoSeekSlider extends StatefulWidget {
  const VideoSeekSlider({
    required this.position,
    required this.duration,
    required this.onChanged,
    required this.onInteraction,
    this.previewFrameLoader,
    this.previewIdentity,
    this.previewPlaceholderPath,
    this.previewDebounce = MediaPreviewTiming.seekPreviewDebounce,
    super.key,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onChanged;
  final VoidCallback onInteraction;
  final SeekPreviewFrameLoader? previewFrameLoader;
  final Object? previewIdentity;
  final String? previewPlaceholderPath;
  final Duration previewDebounce;

  @override
  State<VideoSeekSlider> createState() => _VideoSeekSliderState();
}

class _VideoSeekSliderState extends State<VideoSeekSlider> {
  static const _trackHorizontalInset = 24.0;
  static const _hoverLabelGap = 4.0;

  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  double? _hoverDx;
  SeekPreviewController? _previewController;

  @override
  void initState() {
    super.initState();
    _createPreviewController();
  }

  @override
  void didUpdateWidget(covariant VideoSeekSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewIdentity != widget.previewIdentity ||
        (oldWidget.previewFrameLoader == null) !=
            (widget.previewFrameLoader == null) ||
        oldWidget.previewDebounce != widget.previewDebounce) {
      _disposePreviewController();
      _createPreviewController();
    }
  }

  @override
  void dispose() {
    _disposePreviewController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble().clamp(
      1.0,
      double.infinity,
    );
    final value = widget.position.inMilliseconds.toDouble().clamp(0.0, max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hoverDx = _hoverDx;
        final hoverPosition = hoverDx == null
            ? null
            : _positionAt(hoverDx, constraints.maxWidth);

        return OverlayPortal(
          controller: _overlayController,
          overlayLocation: OverlayChildLocation.rootOverlay,
          overlayChildBuilder: (context) {
            if (hoverDx == null || hoverPosition == null) {
              return const SizedBox.shrink();
            }
            return IgnorePointer(
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.topLeft,
                offset: Offset(
                  _hoverCardLeft(hoverDx, constraints.maxWidth),
                  -(_hoverCardHeight + _hoverLabelGap),
                ),
                child: UnconstrainedBox(
                  alignment: Alignment.topLeft,
                  child: Material(
                    type: MaterialType.transparency,
                    child: VideoSeekPreviewCard(
                      duration: hoverPosition,
                      includeHours: widget.duration.inHours > 0,
                      frameBytes: _previewController?.frameBytes,
                      placeholderPath: widget.previewPlaceholderPath,
                      showFrame: widget.previewFrameLoader != null,
                      isLoading: _previewController?.isLoading ?? false,
                    ),
                  ),
                ),
              ),
            );
          },
          child: CompositedTransformTarget(
            link: _layerLink,
            child: MouseRegion(
              key: const ValueKey('video-seek-hover-region'),
              onEnter: _updateHoverPosition,
              onHover: _updateHoverPosition,
              onExit: (_) => _hideHoverLabel(),
              child: SizedBox(
                height: 48,
                child: Slider(
                  value: value,
                  max: max,
                  onChangeStart: (_) => widget.onInteraction(),
                  onChanged: (value) {
                    widget.onInteraction();
                    widget.onChanged(Duration(milliseconds: value.round()));
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateHoverPosition(PointerEvent event) {
    final hoverDx = event.localPosition.dx;
    final renderBox = context.findRenderObject();
    final width = renderBox is RenderBox ? renderBox.size.width : 0.0;
    final hoverPosition = _positionAt(hoverDx, width);
    _previewController?.request(hoverPosition, widget.duration);
    setState(() => _hoverDx = hoverDx);
    _overlayController.show();
  }

  void _hideHoverLabel() {
    _overlayController.hide();
    _previewController?.cancelPending();
    setState(() => _hoverDx = null);
  }

  Duration _positionAt(double dx, double width) {
    final trackWidth = width - (_trackHorizontalInset * 2);
    if (trackWidth <= 0) return Duration.zero;
    final fraction = ((dx - _trackHorizontalInset) / trackWidth).clamp(
      0.0,
      1.0,
    );
    return Duration(
      milliseconds: (widget.duration.inMilliseconds * fraction).round(),
    );
  }

  double get _hoverCardHeight => widget.previewFrameLoader == null
      ? VideoSeekPreviewCard.labelHeight
      : VideoSeekPreviewCard.imageHeight + VideoSeekPreviewCard.labelHeight;

  double get _hoverCardWidth => widget.previewFrameLoader == null
      ? VideoSeekPreviewCard.labelWidthFor(
          includeHours: widget.duration.inHours > 0,
        )
      : VideoSeekPreviewCard.imageWidth;

  double _hoverCardLeft(double dx, double width) {
    final cardWidth = _hoverCardWidth;
    if (width <= cardWidth) return 0;
    return (dx - (cardWidth / 2)).clamp(0.0, width - cardWidth);
  }

  void _createPreviewController() {
    final loader = widget.previewFrameLoader;
    if (loader == null) return;
    _previewController = SeekPreviewController(
      loadFrame: loader,
      debounceDuration: widget.previewDebounce,
    )..addListener(_handlePreviewChanged);
  }

  void _disposePreviewController() {
    _previewController
      ?..removeListener(_handlePreviewChanged)
      ..dispose();
    _previewController = null;
  }

  void _handlePreviewChanged() {
    if (mounted) setState(() {});
  }
}
