import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';

import 'video_duration_formatter.dart';

class VideoSeekPreviewCard extends StatelessWidget {
  const VideoSeekPreviewCard({
    required this.duration,
    required this.includeHours,
    required this.frameBytes,
    required this.placeholderPath,
    required this.showFrame,
    required this.isLoading,
    super.key,
  });

  static const imageWidth = 176.0;
  static const imageHeight = 99.0;
  static const labelHeight = 28.0;

  final Duration duration;
  final bool includeHours;
  final Uint8List? frameBytes;
  final String? placeholderPath;
  final bool showFrame;
  final bool isLoading;

  static double labelWidthFor({required bool includeHours}) =>
      includeHours ? 76 : 56;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final label = Container(
      key: const ValueKey('video-seek-hover-label'),
      width: showFrame ? null : labelWidthFor(includeHours: includeHours),
      height: labelHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        formatVideoDuration(duration, includeHours: includeHours),
        maxLines: 1,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: appColors.onMedia,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (!showFrame) {
      return DecoratedBox(decoration: _decoration(appColors), child: label);
    }

    return Container(
      key: const ValueKey('video-seek-preview-card'),
      width: imageWidth,
      clipBehavior: Clip.antiAlias,
      decoration: _decoration(appColors, opacity: 0.96),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: ColoredBox(
              color: appColors.mediaBackground,
              child: _buildFrame(appColors),
            ),
          ),
          label,
        ],
      ),
    );
  }

  Widget _buildFrame(AppColorTokens appColors) {
    final bytes = frameBytes;
    if (bytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            bytes,
            key: const ValueKey('video-seek-preview-frame'),
            fit: BoxFit.contain,
            cacheWidth: (imageWidth * 2).round(),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          if (isLoading)
            ColoredBox(color: Colors.black.withValues(alpha: 0.16)),
        ],
      );
    }
    final placeholder = placeholderPath;
    if (placeholder != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.72,
            child: Image.file(
              File(placeholder),
              key: const ValueKey('video-seek-preview-placeholder'),
              fit: BoxFit.contain,
              cacheWidth: (imageWidth * 2).round(),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
        ],
      );
    }
    if (!isLoading) return const SizedBox.shrink();
    return Center(
      child: SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: appColors.onMedia,
        ),
      ),
    );
  }

  BoxDecoration _decoration(AppColorTokens appColors, {double opacity = 0.9}) =>
      BoxDecoration(
        color: appColors.mediaControlSurface.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      );
}
