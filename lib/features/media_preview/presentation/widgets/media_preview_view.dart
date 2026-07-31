import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

import '../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../notifiers/media_preview_notifier.dart';
import '../states/media_preview_ui_state.dart';
import 'filmstrip/media_preview_filmstrip.dart';
import 'filmstrip/media_preview_filmstrip_controller.dart';
import 'image_preview_actions.dart';
import 'media_preview_canvas.dart';
import 'media_preview_interaction_surface.dart';
import 'video_preview_overlays.dart';

class MediaPreviewView extends ConsumerWidget {
  const MediaPreviewView({
    required this.state,
    required this.controlsVisible,
    required this.isFullscreen,
    required this.rotationQuarterTurns,
    required this.isRotationLocked,
    required this.filmstripVisible,
    required this.hdrPlaybackEnabled,
    required this.filmstripController,
    required this.onInteraction,
    required this.onTogglePlayback,
    required this.onControlsHoverChanged,
    required this.onRotate,
    required this.onToggleRotationLock,
    required this.onToggleFilmstrip,
    required this.onToggleHdrPlayback,
    required this.onSelectMedia,
    required this.onToggleFullscreen,
    super.key,
  });

  final MediaPreviewUiState state;
  final bool controlsVisible;
  final bool isFullscreen;
  final int rotationQuarterTurns;
  final bool isRotationLocked;
  final bool filmstripVisible;
  final bool hdrPlaybackEnabled;
  final MediaPreviewFilmstripController filmstripController;
  final VoidCallback onInteraction;
  final VoidCallback onTogglePlayback;
  final ValueChanged<bool> onControlsHoverChanged;
  final VoidCallback onRotate;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onToggleFilmstrip;
  final VoidCallback onToggleHdrPlayback;
  final ValueChanged<int> onSelectMedia;
  final VoidCallback onToggleFullscreen;

  static const _videoControlsFilmstripBottomInset = 84.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = state.activeItem;
    if (item == null) return const Center(child: CircularProgressIndicator());

    final controller = ref.read(mediaPreviewNotifierProvider.notifier);
    final thumbnailPath = item.isVideo
        ? ref.watch(cachedVideoThumbnailProvider(item)).value
        : null;
    var filmstripBottomInset = AppSpacing.lg;
    if (item.isVideo && controlsVisible) {
      filmstripBottomInset = _videoControlsFilmstripBottomInset;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MediaPreviewInteractionSurface(
          key: ValueKey(item.path),
          onTap: item.isVideo ? onTogglePlayback : null,
          onDoubleTap: onToggleFullscreen,
          child: MediaPreviewCanvas(
            itemPath: item.path,
            isVideo: item.isVideo,
            videoController: controller.videoController,
            rotationQuarterTurns: rotationQuarterTurns,
          ),
        ),
        if (!item.isVideo)
          ImagePreviewActions(
            visible: controlsVisible,
            isRotationLocked: isRotationLocked,
            filmstripVisible: filmstripVisible,
            bottomInset: filmstripVisible
                ? MediaPreviewFilmstrip.overlayHeight + AppSpacing.xxl
                : AppSpacing.lg,
            onRotate: onRotate,
            onToggleRotationLock: onToggleRotationLock,
            onToggleFilmstrip: onToggleFilmstrip,
            onInteraction: onInteraction,
          ),
        if (item.isVideo)
          VideoPreviewOverlays(
            itemPath: item.path,
            thumbnailPath: thumbnailPath,
            state: state,
            controlsVisible: controlsVisible,
            isFullscreen: isFullscreen,
            rotationQuarterTurns: rotationQuarterTurns,
            isRotationLocked: isRotationLocked,
            filmstripVisible: filmstripVisible,
            hdrPlaybackEnabled: hdrPlaybackEnabled,
            onTogglePlayback: onTogglePlayback,
            onControlsHoverChanged: onControlsHoverChanged,
            onRotate: onRotate,
            onToggleRotationLock: onToggleRotationLock,
            onToggleFilmstrip: onToggleFilmstrip,
            onToggleHdrPlayback: onToggleHdrPlayback,
            onToggleFullscreen: onToggleFullscreen,
            onInteraction: onInteraction,
          ),
        MediaPreviewFilmstrip(
          items: state.items,
          activeIndex: state.activeIndex,
          visible: filmstripVisible,
          bottomInset: filmstripBottomInset,
          controller: filmstripController,
          onSelected: onSelectMedia,
        ),
      ],
    );
  }
}
