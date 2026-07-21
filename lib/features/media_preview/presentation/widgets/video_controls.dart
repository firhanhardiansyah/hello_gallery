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
    required this.onInteraction,
    super.key,
  });

  final MediaPreviewUiState state;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(mediaPreviewNotifierProvider.notifier);
    final appColors = context.appColors;
    final max = state.duration.inMilliseconds.toDouble().clamp(
      1.0,
      double.infinity,
    );
    final value = state.position.inMilliseconds.toDouble().clamp(0.0, max);
    return Container(
      color: appColors.mediaControlSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: state.isPlaying ? 'Pause' : 'Play',
            onPressed: () {
              onInteraction();
              controller.togglePlay();
            },
            icon: HugeIcon(
              icon: state.isPlaying
                  ? HugeIcons.strokeRoundedPause
                  : HugeIcons.strokeRoundedPlay,
              color: appColors.onMedia,
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              max: max,
              onChanged: (value) {
                onInteraction();
                controller.seek(Duration(milliseconds: value.round()));
              },
            ),
          ),
          Text(
            '${_formatDuration(state.position)} / '
            '${_formatDuration(state.duration)}',
            style: TextStyle(color: appColors.onMedia),
          ),
          IconButton(
            tooltip: state.isLooping ? 'Disable loop' : 'Loop video',
            onPressed: () {
              onInteraction();
              controller.toggleLoop();
            },
            icon: HugeIcon(
              icon: state.isLooping
                  ? HugeIcons.strokeRoundedRepeatOne01
                  : HugeIcons.strokeRoundedRepeatOff,
              color: state.isLooping
                  ? Theme.of(context).colorScheme.primary
                  : appColors.onMedia,
            ),
          ),
          IconButton(
            tooltip: state.isMuted ? 'Unmute' : 'Mute',
            onPressed: () {
              onInteraction();
              controller.toggleMute();
            },
            icon: HugeIcon(
              icon: state.isMuted
                  ? HugeIcons.strokeRoundedVolumeOff
                  : HugeIcons.strokeRoundedVolumeHigh,
              color: appColors.onMedia,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
