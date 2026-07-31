import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

class VideoSeekSlider extends StatefulWidget {
  const VideoSeekSlider({
    required this.position,
    required this.duration,
    required this.onChanged,
    required this.onInteraction,
    super.key,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onChanged;
  final VoidCallback onInteraction;

  @override
  State<VideoSeekSlider> createState() => _VideoSeekSliderState();
}

class _VideoSeekSliderState extends State<VideoSeekSlider> {
  static const _trackHorizontalInset = 24.0;
  static const _hoverLabelHeight = 28.0;
  static const _hoverLabelGap = 4.0;

  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  double? _hoverDx;

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
                  _hoverLabelLeft(hoverDx, constraints.maxWidth),
                  -(_hoverLabelHeight + _hoverLabelGap),
                ),
                child: UnconstrainedBox(
                  alignment: Alignment.topLeft,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _SeekHoverLabel(
                      duration: hoverPosition,
                      includeHours: widget.duration.inHours > 0,
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
    setState(() => _hoverDx = event.localPosition.dx);
    _overlayController.show();
  }

  void _hideHoverLabel() {
    _overlayController.hide();
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

  double _hoverLabelLeft(double dx, double width) {
    final labelWidth = _SeekHoverLabel.widthFor(
      includeHours: widget.duration.inHours > 0,
    );
    if (width <= labelWidth) return 0;
    return (dx - (labelWidth / 2)).clamp(0.0, width - labelWidth);
  }
}

class _SeekHoverLabel extends StatelessWidget {
  const _SeekHoverLabel({required this.duration, required this.includeHours});

  final Duration duration;
  final bool includeHours;

  static double widthFor({required bool includeHours}) =>
      includeHours ? 76 : 56;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      key: const ValueKey('video-seek-hover-label'),
      width: widthFor(includeHours: includeHours),
      height: _VideoSeekSliderState._hoverLabelHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: appColors.mediaControlSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        formatVideoDuration(duration, includeHours: includeHours),
        maxLines: 1,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: appColors.onMedia,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String formatVideoDuration(Duration value, {required bool includeHours}) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (!includeHours) return '$minutes:$seconds';
  final hours = value.inHours.toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
