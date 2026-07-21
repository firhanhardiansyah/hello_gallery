import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../notifiers/media_preview_notifier.dart';
import '../states/media_preview_ui_state.dart';
import 'media_preview_canvas.dart';
import 'media_preview_interaction_surface.dart';
import 'image_preview_actions.dart';
import 'video_preview_overlays.dart';

class MediaPreviewView extends ConsumerWidget {
  const MediaPreviewView({
    required this.state,
    required this.controlsVisible,
    required this.isFullscreen,
    required this.rotationQuarterTurns,
    required this.onInteraction,
    required this.onRotate,
    required this.onToggleFullscreen,
    super.key,
  });

  final MediaPreviewUiState state;
  final bool controlsVisible;
  final bool isFullscreen;
  final int rotationQuarterTurns;
  final VoidCallback onInteraction;
  final VoidCallback onRotate;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = state.activeItem;
    if (item == null) return const Center(child: CircularProgressIndicator());

    final controller = ref.read(mediaPreviewNotifierProvider.notifier);
    final thumbnailPath = item.isVideo
        ? ref.watch(cachedVideoThumbnailProvider(item)).value
        : null;
    void togglePlayback() {
      onInteraction();
      controller.togglePlay();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MediaPreviewInteractionSurface(
          key: ValueKey(item.path),
          onTap: item.isVideo ? togglePlayback : null,
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
            onRotate: onRotate,
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
            onTogglePlayback: togglePlayback,
            onRotate: onRotate,
            onToggleFullscreen: onToggleFullscreen,
            onInteraction: onInteraction,
          ),
      ],
    );
  }
}
