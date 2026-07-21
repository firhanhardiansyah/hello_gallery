import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaPreviewCanvas extends StatelessWidget {
  const MediaPreviewCanvas({
    required this.itemPath,
    required this.isVideo,
    required this.videoController,
    required this.rotationQuarterTurns,
    super.key,
  });

  final String itemPath;
  final bool isVideo;
  final VideoController? videoController;
  final int rotationQuarterTurns;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.appColors.mediaBackground,
    child: isVideo ? _buildVideo() : _buildImage(context),
  );

  Widget _buildVideo() {
    final controller = videoController;
    return RotatedBox(
      quarterTurns: rotationQuarterTurns,
      child: controller == null
          ? const Center(child: CircularProgressIndicator())
          : Video(
              key: ValueKey('video:$itemPath'),
              controller: controller,
              controls: NoVideoControls,
            ),
    );
  }

  Widget _buildImage(BuildContext context) => InteractiveViewer(
    key: ValueKey('image-viewer:$itemPath:$rotationQuarterTurns'),
    minScale: 0.5,
    maxScale: 5,
    child: RotatedBox(
      quarterTurns: rotationQuarterTurns,
      child: Image.file(
        File(itemPath),
        key: ValueKey('image:$itemPath'),
        fit: BoxFit.contain,
        gaplessPlayback: false,
        frameBuilder: (context, child, frame, syncLoaded) {
          if (syncLoaded || frame != null) return child;
          return ColoredBox(
            color: context.appColors.mediaBackground,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    ),
  );
}
