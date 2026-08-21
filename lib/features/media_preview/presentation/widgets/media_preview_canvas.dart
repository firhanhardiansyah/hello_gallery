import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaPreviewCanvas extends StatefulWidget {
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
  State<MediaPreviewCanvas> createState() => _MediaPreviewCanvasState();
}

class _MediaPreviewCanvasState extends State<MediaPreviewCanvas> {
  static const _minScale = 1.0;
  static const _maxScale = 5.0;
  static const _scaleFactor = 400.0;

  final _transformationController = TransformationController();
  bool _zoomModifierPressed = false;

  @override
  void initState() {
    super.initState();
    _zoomModifierPressed = _isPrimaryModifierPressed();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void didUpdateWidget(covariant MediaPreviewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemPath != widget.itemPath ||
        oldWidget.rotationQuarterTurns != widget.rotationQuarterTurns) {
      _transformationController.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _transformationController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    final modifierPressed = _isPrimaryModifierPressed();
    if (_zoomModifierPressed != modifierPressed && mounted) {
      setState(() => _zoomModifierPressed = modifierPressed);
    }
    return false;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_zoomModifierPressed) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      _handleResolvedZoomSignal,
    );
  }

  void _handleResolvedZoomSignal(PointerEvent event) {
    if (event is! PointerScrollEvent) return;
    event.respond(allowPlatformDefault: false);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _handlePointerSignal,
    child: ColoredBox(
      color: context.appColors.mediaBackground,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: _minScale,
        maxScale: _maxScale,
        scaleFactor: _scaleFactor,
        scaleEnabled: _zoomModifierPressed,
        trackpadScrollCausesScale: true,
        child: widget.isVideo ? _buildVideo() : _buildImage(context),
      ),
    ),
  );

  Widget _buildVideo() {
    final controller = widget.videoController;
    return RotatedBox(
      quarterTurns: widget.rotationQuarterTurns,
      child: controller == null
          ? const Center(child: CircularProgressIndicator())
          : Video(
              key: ValueKey('video:${widget.itemPath}'),
              controller: controller,
              controls: NoVideoControls,
            ),
    );
  }

  Widget _buildImage(BuildContext context) => RotatedBox(
    quarterTurns: widget.rotationQuarterTurns,
    child: Image.file(
      File(widget.itemPath),
      key: ValueKey('image:${widget.itemPath}'),
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
  );
}

bool _isPrimaryModifierPressed() {
  final keyboard = HardwareKeyboard.instance;
  return keyboard.isControlPressed || keyboard.isMetaPressed;
}
