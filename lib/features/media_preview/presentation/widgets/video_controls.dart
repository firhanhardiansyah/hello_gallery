import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

import '../notifiers/media_preview_notifier.dart';
import '../states/media_preview_ui_state.dart';

class VideoControls extends ConsumerWidget {
  const VideoControls({
    required this.state,
    required this.isFullscreen,
    required this.isRotationLocked,
    required this.filmstripVisible,
    required this.onInteraction,
    required this.onRotate,
    required this.onToggleRotationLock,
    required this.onToggleFilmstrip,
    required this.onToggleFullscreen,
    super.key,
  });

  final MediaPreviewUiState state;
  final bool isFullscreen;
  final bool isRotationLocked;
  final bool filmstripVisible;
  final VoidCallback onInteraction;
  final VoidCallback onRotate;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onToggleFilmstrip;
  final VoidCallback onToggleFullscreen;

  static const _controlSize = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(mediaPreviewNotifierProvider.notifier);

    final max = state.duration.inMilliseconds.toDouble().clamp(
      1.0,
      double.infinity,
    );

    final value = state.position.inMilliseconds.toDouble().clamp(0.0, max);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: value,
            max: max,
            onChanged: (value) {
              onInteraction();

              controller.seek(Duration(milliseconds: value.round()));
            },
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
                  onInteraction();
                  controller.togglePlay();
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
    final appColors = context.appColors;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(_controlSize),
        backgroundColor: _surfaceColor(context),
        hoverColor: appColors.mediaControlSurface.withValues(alpha: 0.2),
        highlightColor: appColors.mediaControlSurface.withValues(alpha: 0.3),
      ),
      icon: HugeIcon(icon: icon, color: color ?? appColors.onMedia),
    );
  }

  Widget _buildDuration(BuildContext context) {
    final appColors = context.appColors;
    final includeHours = state.duration.inHours > 0;

    return Container(
      height: _controlSize,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(_controlSize / 2),
      ),
      child: Text(
        '${_formatDuration(state.position, includeHours: includeHours)} / '
        '${_formatDuration(state.duration, includeHours: includeHours)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: appColors.onMedia,
          fontWeight: FontWeight.w500,
        ),
      ),
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

String _formatDuration(Duration value, {required bool includeHours}) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (!includeHours) return '$minutes:$seconds';
  final hours = value.inHours.toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
