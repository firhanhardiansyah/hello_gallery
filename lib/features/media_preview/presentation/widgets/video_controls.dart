import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/core/widgets/media_overlay_icon_button.dart';
import 'package:hugeicons/hugeicons.dart';

import '../notifiers/media_preview_notifier.dart';
import '../states/media_preview_ui_state.dart';
import 'video_seek_slider.dart';

class VideoControls extends ConsumerWidget {
  const VideoControls({
    required this.state,
    required this.isFullscreen,
    required this.isRotationLocked,
    required this.filmstripVisible,
    required this.hdrPlaybackEnabled,
    required this.onInteraction,
    required this.onTogglePlayback,
    required this.onRotate,
    required this.onToggleRotationLock,
    required this.onToggleFilmstrip,
    required this.onToggleHdrPlayback,
    required this.onToggleFullscreen,
    super.key,
  });

  final MediaPreviewUiState state;
  final bool isFullscreen;
  final bool isRotationLocked;
  final bool filmstripVisible;
  final bool hdrPlaybackEnabled;
  final VoidCallback onInteraction;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRotate;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onToggleFilmstrip;
  final VoidCallback onToggleHdrPlayback;
  final VoidCallback onToggleFullscreen;

  static const _controlSize = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(mediaPreviewNotifierProvider.notifier);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoSeekSlider(
            position: state.position,
            duration: state.duration,
            onInteraction: onInteraction,
            onChanged: controller.seek,
          ),
          Row(
            children: [
              _buildControlButton(
                context: context,
                tooltip: state.isPlaying ? 'Pause' : 'Play',
                icon: state.isPlaying
                    ? HugeIcons.strokeRoundedPause
                    : HugeIcons.strokeRoundedPlay,
                onPressed: () {
                  onTogglePlayback();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildControlButton(
                context: context,
                tooltip: state.isMuted ? 'Unmute' : 'Mute',
                icon: state.isMuted
                    ? HugeIcons.strokeRoundedVolumeOff
                    : HugeIcons.strokeRoundedVolumeHigh,
                onPressed: () {
                  onInteraction();
                  controller.toggleMute();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildDuration(context),
              const Spacer(),
              _buildControlGroup(
                context: context,
                actions: [
                  _VideoControlAction(
                    tooltip: state.isLooping ? 'Disable loop' : 'Loop video',
                    icon: state.isLooping
                        ? HugeIcons.strokeRoundedRepeatOne01
                        : HugeIcons.strokeRoundedRepeatOff,
                    color: state.isLooping
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    onPressed: () {
                      onInteraction();
                      controller.toggleLoop();
                    },
                  ),
                  _VideoControlAction(
                    tooltip: 'Rotate clockwise',
                    icon: HugeIcons.strokeRoundedRotateClockwise,
                    onPressed: () {
                      onInteraction();
                      onRotate();
                    },
                  ),
                  _VideoControlAction(
                    tooltip: isRotationLocked
                        ? 'Unlock rotation'
                        : 'Lock rotation',
                    icon: isRotationLocked
                        ? HugeIcons.strokeRoundedScreenLockRotation
                        : HugeIcons.strokeRoundedSquareUnlock01,
                    color: isRotationLocked
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    onPressed: () {
                      onInteraction();
                      onToggleRotationLock();
                    },
                  ),
                  _VideoControlAction(
                    tooltip: filmstripVisible
                        ? 'Hide media list (G)'
                        : 'Show media list (G)',
                    icon: HugeIcons.strokeRoundedGalleryHorizontalEnd,
                    color: filmstripVisible
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    onPressed: () {
                      onInteraction();
                      onToggleFilmstrip();
                    },
                  ),
                  _VideoControlAction(
                    tooltip: hdrPlaybackEnabled
                        ? 'Disable HDR playback'
                        : 'Enable HDR playback',
                    icon: HugeIcons.strokeRoundedHdr01,
                    color: hdrPlaybackEnabled
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    onPressed: () {
                      onInteraction();
                      onToggleHdrPlayback();
                    },
                  ),
                  _VideoControlAction(
                    tooltip: isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
                    icon: isFullscreen
                        ? HugeIcons.strokeRoundedMinimizeScreen
                        : HugeIcons.strokeRoundedMaximizeScreen,
                    onPressed: () {
                      onInteraction();
                      onToggleFullscreen();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required String tooltip,
    required List<List<dynamic>> icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return MediaOverlayIconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      color: color,
      size: _controlSize,
    );
  }

  Widget _buildDuration(BuildContext context) {
    return _VideoDurationButton(
      position: state.position,
      duration: state.duration,
      height: _controlSize,
      backgroundColor: _surfaceColor(context),
      onInteraction: onInteraction,
    );
  }

  Widget _buildControlGroup({
    required BuildContext context,
    required List<_VideoControlAction> actions,
  }) {
    final appColors = context.appColors;
    return Container(
      key: const ValueKey('video-secondary-controls'),
      height: _controlSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(_controlSize / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            if (index > 0)
              Container(
                width: 1,
                height: _controlSize / 2,
                color: appColors.onMediaMuted.withValues(alpha: 0.35),
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
            IconButton(
              tooltip: actions[index].tooltip,
              onPressed: actions[index].onPressed,
              style: IconButton.styleFrom(
                fixedSize: const Size.square(_controlSize),
                backgroundColor: Colors.transparent,
                hoverColor: appColors.mediaControlSurface.withValues(
                  alpha: 0.2,
                ),
                highlightColor: appColors.mediaControlSurface.withValues(
                  alpha: 0.3,
                ),
              ),
              icon: HugeIcon(
                icon: actions[index].icon,
                color: actions[index].color ?? appColors.onMedia,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _surfaceColor(BuildContext context) {
    return context.appColors.mediaControlSurface.withValues(alpha: 0.3);
  }
}

class _VideoDurationButton extends StatefulWidget {
  const _VideoDurationButton({
    required this.position,
    required this.duration,
    required this.height,
    required this.backgroundColor,
    required this.onInteraction,
  });

  final Duration position;
  final Duration duration;
  final double height;
  final Color backgroundColor;
  final VoidCallback onInteraction;

  @override
  State<_VideoDurationButton> createState() => _VideoDurationButtonState();
}

class _VideoDurationButtonState extends State<_VideoDurationButton> {
  bool _showRemaining = false;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final includeHours = widget.duration.inHours > 0;
    final elapsed = widget.position > widget.duration
        ? widget.duration
        : widget.position;
    final remaining = widget.duration - elapsed;
    final leadingDuration = _showRemaining
        ? '-${formatVideoDuration(remaining, includeHours: includeHours)}'
        : formatVideoDuration(elapsed, includeHours: includeHours);
    final totalDuration = formatVideoDuration(
      widget.duration,
      includeHours: includeHours,
    );
    final borderRadius = BorderRadius.circular(widget.height / 2);

    return Semantics(
      button: true,
      child: Tooltip(
        message: _showRemaining ? 'Show elapsed time' : 'Show remaining time',
        child: Material(
          key: const ValueKey('video-duration-button'),
          color: widget.backgroundColor,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: borderRadius,
            hoverColor: appColors.mediaControlSurface.withValues(alpha: 0.2),
            highlightColor: appColors.mediaControlSurface.withValues(
              alpha: 0.3,
            ),
            onTap: () {
              widget.onInteraction();
              setState(() => _showRemaining = !_showRemaining);
            },
            child: SizedBox(
              height: widget.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  child: Text(
                    '$leadingDuration / $totalDuration',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: appColors.onMedia,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoControlAction {
  const _VideoControlAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final List<List<dynamic>> icon;
  final VoidCallback onPressed;
  final Color? color;
}
