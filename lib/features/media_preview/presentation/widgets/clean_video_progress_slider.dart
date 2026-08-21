import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';

class CleanVideoProgressSlider extends StatefulWidget {
  const CleanVideoProgressSlider({
    required this.position,
    required this.duration,
    required this.onChanged,
    super.key,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onChanged;

  @override
  State<CleanVideoProgressSlider> createState() =>
      _CleanVideoProgressSliderState();
}

class _CleanVideoProgressSliderState extends State<CleanVideoProgressSlider> {
  static const _interactionHeight = 20.0;
  static const _idleTrackHeight = 3.0;
  static const _activeTrackHeight = 6.0;
  static const _activeTrackBottom = 3.0;
  static const _thumbSize = 12.0;
  static const _animationDuration = Duration(milliseconds: 120);

  bool _hovered = false;
  bool _dragging = false;

  bool get _active => _hovered || _dragging;

  @override
  Widget build(BuildContext context) {
    if (widget.duration <= Duration.zero) return const SizedBox.shrink();

    final durationMilliseconds = widget.duration.inMilliseconds;
    final positionMilliseconds = widget.position.inMilliseconds.clamp(
      0,
      durationMilliseconds,
    );
    final progress = positionMilliseconds / durationMilliseconds;

    return Semantics(
      slider: true,
      label: 'Video progress',
      value: '${(progress * 100).round()}%',
      child: MouseRegion(
        key: const ValueKey('clean-video-progress-hover-region'),
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) =>
                _seek(details.localPosition.dx, constraints),
            onHorizontalDragStart: (details) {
              setState(() => _dragging = true);
              _seek(details.localPosition.dx, constraints);
            },
            onHorizontalDragUpdate: (details) =>
                _seek(details.localPosition.dx, constraints),
            onHorizontalDragEnd: (_) => setState(() => _dragging = false),
            onHorizontalDragCancel: () => setState(() => _dragging = false),
            child: SizedBox(
              height: _interactionHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    key: const ValueKey('clean-video-progress-track'),
                    duration: _animationDuration,
                    curve: Curves.easeOut,
                    left: 0,
                    right: 0,
                    bottom: _active ? _activeTrackBottom : 0,
                    height: _active ? _activeTrackHeight : _idleTrackHeight,
                    child: ColoredBox(
                      color: context.appColors.onMediaMuted.withValues(
                        alpha: 0.35,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          key: const ValueKey('clean-video-progress-value'),
                          widthFactor: progress,
                          heightFactor: 1,
                          child: ColoredBox(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_active)
                    Positioned(
                      left:
                          (constraints.maxWidth * progress) - (_thumbSize / 2),
                      bottom: 0,
                      child: DecoratedBox(
                        key: const ValueKey('clean-video-progress-thumb'),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: _thumbSize),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _seek(double dx, BoxConstraints constraints) {
    if (constraints.maxWidth <= 0 || widget.duration <= Duration.zero) return;
    final fraction = (dx / constraints.maxWidth).clamp(0.0, 1.0);
    widget.onChanged(
      Duration(
        milliseconds: (widget.duration.inMilliseconds * fraction).round(),
      ),
    );
  }
}
