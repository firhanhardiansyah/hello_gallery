import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hugeicons/hugeicons.dart';

import '../states/media_preview_ui_state.dart';
import 'video_controls.dart';

class VideoPreviewOverlays extends StatelessWidget {
  const VideoPreviewOverlays({
    required this.itemPath,
    required this.thumbnailPath,
    required this.state,
    required this.controlsVisible,
    required this.isFullscreen,
    required this.rotationQuarterTurns,
    required this.isRotationLocked,
    required this.filmstripVisible,
    required this.hdrPlaybackEnabled,
    required this.onTogglePlayback,
    required this.onRotate,
    required this.onToggleRotationLock,
    required this.onToggleFilmstrip,
    required this.onToggleHdrPlayback,
    required this.onToggleFullscreen,
    required this.onInteraction,
    super.key,
  });

  final String itemPath;
  final String? thumbnailPath;
  final MediaPreviewUiState state;
  final bool controlsVisible;
  final bool isFullscreen;
  final int rotationQuarterTurns;
  final bool isRotationLocked;
  final bool filmstripVisible;
  final bool hdrPlaybackEnabled;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRotate;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onToggleFilmstrip;
  final VoidCallback onToggleHdrPlayback;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        _VideoLoadingOverlay(
          itemPath: itemPath,
          thumbnailPath: thumbnailPath,
          isReady: state.isVideoReady,
          rotationQuarterTurns: rotationQuarterTurns,
        ),
        _VideoPlaybackButton(
          isPlaying: state.isPlaying,
          visible: controlsVisible,
          onPressed: onTogglePlayback,
        ),
        _VideoControlsOverlay(
          state: state,
          visible: controlsVisible,
          isFullscreen: isFullscreen,
          isRotationLocked: isRotationLocked,
          filmstripVisible: filmstripVisible,
          hdrPlaybackEnabled: hdrPlaybackEnabled,
          onRotate: onRotate,
          onToggleRotationLock: onToggleRotationLock,
          onToggleFilmstrip: onToggleFilmstrip,
          onToggleHdrPlayback: onToggleHdrPlayback,
          onInteraction: onInteraction,
          onToggleFullscreen: onToggleFullscreen,
        ),
      ],
    ),
  );
}

class _VideoLoadingOverlay extends StatelessWidget {
  const _VideoLoadingOverlay({
    required this.itemPath,
    required this.thumbnailPath,
    required this.isReady,
    required this.rotationQuarterTurns,
  });

  final String itemPath;
  final String? thumbnailPath;
  final bool isReady;
  final int rotationQuarterTurns;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: isReady ? 0 : 1,
        child: ColoredBox(
          color: context.appColors.mediaBackground,
          child: RotatedBox(
            quarterTurns: rotationQuarterTurns,
            child: thumbnailPath == null
                ? const _VideoLoadingPlaceholder()
                : Image.file(
                    File(thumbnailPath!),
                    key: ValueKey('thumbnail:$itemPath'),
                    fit: BoxFit.contain,
                    cacheWidth: 960,
                    errorBuilder: (_, _, _) => const _VideoLoadingPlaceholder(),
                  ),
          ),
        ),
      ),
    ),
  );
}

class _VideoLoadingPlaceholder extends StatelessWidget {
  const _VideoLoadingPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
    child: HugeIcon(
      icon: HugeIcons.strokeRoundedPlayCircle,
      size: 72,
      color: context.appColors.onMediaMuted,
    ),
  );
}

class _VideoPlaybackButton extends StatelessWidget {
  const _VideoPlaybackButton({
    required this.isPlaying,
    required this.visible,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: IconButton.filled(
            tooltip: isPlaying ? 'Pause' : 'Play',
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: appColors.mediaControlSurface.withValues(
                alpha: 0.3,
              ),
              foregroundColor: appColors.onMedia,
              minimumSize: const Size.square(72),
              iconSize: 42,
              hoverColor: appColors.mediaControlSurface.withValues(alpha: 0.2),
              highlightColor: appColors.mediaControlSurface.withValues(
                alpha: 0.3,
              ),
            ),
            icon: HugeIcon(
              icon: isPlaying
                  ? HugeIcons.strokeRoundedPause
                  : HugeIcons.strokeRoundedPlay,
              size: 42,
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoControlsOverlay extends StatelessWidget {
  const _VideoControlsOverlay({
    required this.state,
    required this.visible,
    required this.isFullscreen,
    required this.isRotationLocked,
    required this.filmstripVisible,
    required this.hdrPlaybackEnabled,
    required this.onRotate,
    required this.onToggleRotationLock,
    required this.onToggleFilmstrip,
    required this.onToggleHdrPlayback,
    required this.onInteraction,
    required this.onToggleFullscreen,
  });

  final MediaPreviewUiState state;
  final bool visible;
  final bool isFullscreen;
  final bool isRotationLocked;
  final bool filmstripVisible;
  final bool hdrPlaybackEnabled;
  final VoidCallback onRotate;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onToggleFilmstrip;
  final VoidCallback onToggleHdrPlayback;
  final VoidCallback onInteraction;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: VideoControls(
            state: state,
            isFullscreen: isFullscreen,
            isRotationLocked: isRotationLocked,
            filmstripVisible: filmstripVisible,
            hdrPlaybackEnabled: hdrPlaybackEnabled,
            onRotate: onRotate,
            onToggleRotationLock: onToggleRotationLock,
            onToggleFilmstrip: onToggleFilmstrip,
            onToggleHdrPlayback: onToggleHdrPlayback,
            onInteraction: onInteraction,
            onToggleFullscreen: onToggleFullscreen,
          ),
        ),
      ),
    ),
  );
}
