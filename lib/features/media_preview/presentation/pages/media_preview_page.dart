import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';
import 'package:hello_gallery/core/theme/app_color_tokens.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../thumbnail/application/providers/thumbnail_dependencies.dart';
import '../input/media_preview_scroll_input.dart';
import '../notifiers/media_preview_notifier.dart';
import '../states/media_preview_ui_state.dart';
import '../widgets/media_preview_interaction_surface.dart';

class MediaPreviewPage extends ConsumerStatefulWidget {
  const MediaPreviewPage({
    required this.items,
    required this.initialIndex,
    required this.rootPath,
    required this.currentFolderPath,
    required this.sort,
    this.embedded = false,
    this.sidebarVisible = true,
    this.onToggleSidebar,
    this.onClose,
    this.isFullscreen = false,
    this.onToggleFullscreen,
    super.key,
  });

  final List<MediaItem> items;
  final int initialIndex;
  final String rootPath;
  final String currentFolderPath;
  final GallerySort sort;
  final bool embedded;
  final bool sidebarVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onClose;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;

  @override
  ConsumerState<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends ConsumerState<MediaPreviewPage> {
  final _focusNode = FocusNode();
  final _scrollInput = MediaPreviewScrollInput();
  Timer? _hideTimer;
  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;
  bool _controlsVisible = true;
  bool _controlsHiddenByNavigation = false;
  int _silentNavigationCount = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    _gamepadSubscription = Gamepads.normalizedEvents.listen(
      _handleGamepadEvent,
    );
    Future.microtask(() async {
      await ref
          .read(mediaPreviewNotifierProvider.notifier)
          .configure(widget.items, widget.initialIndex);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    unawaited(_gamepadSubscription?.cancel());
    _hideTimer?.cancel();
    _scrollInput.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showControls({bool restartTimer = true, bool userInitiated = false}) {
    if (_controlsHiddenByNavigation && !userInitiated) return;
    if (userInitiated) _controlsHiddenByNavigation = false;
    _hideTimer?.cancel();
    if (!_controlsVisible && mounted) {
      setState(() => _controlsVisible = true);
    }
    final state = ref.read(mediaPreviewNotifierProvider);
    if (!restartTimer ||
        !state.isPlaying ||
        state.activeItem?.isVideo != true) {
      return;
    }
    _hideTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final latest = ref.read(mediaPreviewNotifierProvider);
      if (latest.isPlaying && latest.activeItem?.isVideo == true) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _handlePointerActivity() {
    _showControls(userInitiated: true);
  }

  void _toggleSidebar() => widget.onToggleSidebar?.call();

  void _toggleFullscreen() => widget.onToggleFullscreen?.call();

  void _navigateWithoutRevealingControls(Future<void> Function() navigate) {
    _suppressControlsDuringNavigation();
    unawaited(navigate());
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final direction = _scrollInput.handle(event.scrollDelta);
    if (direction == 0) return;
    final controller = ref.read(mediaPreviewNotifierProvider.notifier);
    _navigateWithoutRevealingControls(
      direction > 0 ? controller.next : controller.previous,
    );
  }

  void _suppressControlsDuringNavigation() {
    _controlsHiddenByNavigation = true;
    _hideTimer?.cancel();
    if (_controlsVisible && mounted) {
      setState(() => _controlsVisible = false);
    }
    _silentNavigationCount++;
    unawaited(
      Future<void>(() async {
        // media_kit may emit its final playing event immediately after open.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _silentNavigationCount--;
      }),
    );
  }

  bool _handleGlobalKey(KeyEvent event) {
    return _onKey(event) == KeyEventResult.handled;
  }

  void _handleGamepadEvent(NormalizedGamepadEvent event) {
    if (!mounted) return;
    final button = event.button;
    if (button != null) {
      if (event.value < 0.5) return;
      _handleGamepadButton(button);
      return;
    }

    // Analog axes are handled by the shell-level virtual cursor overlay.
  }

  void _handleGamepadButton(GamepadButton button) {
    final controller = ref.read(mediaPreviewNotifierProvider.notifier);
    switch (button) {
      case GamepadButton.dpadUp:
        _navigateWithoutRevealingControls(controller.previous);
      case GamepadButton.dpadDown:
        _navigateWithoutRevealingControls(controller.next);
      case GamepadButton.dpadLeft:
        _showControls(userInitiated: true);
        controller.seekBy(const Duration(seconds: -3));
      case GamepadButton.dpadRight:
        _showControls(userInitiated: true);
        controller.seekBy(const Duration(seconds: 3));
      case GamepadButton.a:
        _showControls(userInitiated: true);
        controller.togglePlay();
      case GamepadButton.x:
        _showControls(userInitiated: true);
        controller.toggleMute();
      case GamepadButton.y:
      case GamepadButton.start:
        _toggleFullscreen();
      case GamepadButton.back:
      case GamepadButton.touchpad:
        _toggleSidebar();
      case GamepadButton.b:
        widget.onClose?.call();
      case GamepadButton.home:
      case GamepadButton.leftBumper:
      case GamepadButton.rightBumper:
      case GamepadButton.leftTrigger:
      case GamepadButton.rightTrigger:
      case GamepadButton.leftStick:
      case GamepadButton.rightStick:
        return;
    }
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final controller = ref.read(mediaPreviewNotifierProvider.notifier);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _focusNode.requestFocus();
        _navigateWithoutRevealingControls(controller.previous);
      case LogicalKeyboardKey.arrowDown:
        _focusNode.requestFocus();
        _navigateWithoutRevealingControls(controller.next);
      case LogicalKeyboardKey.arrowLeft:
        _showControls(userInitiated: true);
        controller.seekBy(const Duration(seconds: -3));
      case LogicalKeyboardKey.arrowRight:
        _showControls(userInitiated: true);
        controller.seekBy(const Duration(seconds: 3));
      case LogicalKeyboardKey.space:
        _showControls(userInitiated: true);
        controller.togglePlay();
      case LogicalKeyboardKey.keyM:
        _showControls(userInitiated: true);
        controller.toggleMute();
      case LogicalKeyboardKey.keyS:
        _toggleSidebar();
      case LogicalKeyboardKey.keyF:
        _toggleFullscreen();
      case LogicalKeyboardKey.escape:
        if (widget.isFullscreen) {
          _toggleFullscreen();
        } else {
          final onClose = widget.onClose;
          if (onClose != null) {
            onClose();
          } else {
            Navigator.of(context).maybePop();
          }
        }
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaPreviewNotifierProvider);
    ref.listen(
      mediaPreviewNotifierProvider.select((value) => value.activeIndex),
      (previous, activeIndex) {
        if (previous != activeIndex) {
          _suppressControlsDuringNavigation();
        }
      },
    );
    ref.listen(
      mediaPreviewNotifierProvider.select((value) => value.isPlaying),
      (previous, isPlaying) {
        if (_silentNavigationCount > 0) return;
        if (isPlaying) {
          _showControls();
        } else {
          _showControls(restartTimer: false);
        }
      },
    );
    return Focus(
      focusNode: _focusNode,
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: MouseRegion(
          cursor: state.isPlaying && !_controlsVisible
              ? SystemMouseCursors.none
              : MouseCursor.defer,
          onEnter: (_) => _handlePointerActivity(),
          onHover: (_) => _handlePointerActivity(),
          child: _Preview(
            state: state,
            controlsVisible: _controlsVisible,
            onInteraction: () => _showControls(userInitiated: true),
            onToggleFullscreen: _toggleFullscreen,
          ),
        ),
      ),
    );
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({
    required this.state,
    required this.controlsVisible,
    required this.onInteraction,
    required this.onToggleFullscreen,
  });
  final MediaPreviewUiState state;
  final bool controlsVisible;
  final VoidCallback onInteraction;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = state.activeItem;
    final controller = ref.read(mediaPreviewNotifierProvider.notifier);
    final appColors = context.appColors;
    if (item == null) return const Center(child: CircularProgressIndicator());
    final cachedThumbnail = item.isVideo
        ? ref.watch(cachedVideoThumbnailProvider(item))
        : null;
    final thumbnailPath = cachedThumbnail?.value;
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
          child: ColoredBox(
            color: appColors.mediaBackground,
            child: item.isVideo
                ? controller.videoController == null
                      ? const Center(child: CircularProgressIndicator())
                      : Video(
                          key: ValueKey('video:${item.path}'),
                          controller: controller.videoController!,
                          controls: NoVideoControls,
                        )
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Image.file(
                      File(item.path),
                      key: ValueKey('image:${item.path}'),
                      fit: BoxFit.contain,
                      gaplessPlayback: false,
                      frameBuilder: (context, child, frame, syncLoaded) {
                        if (syncLoaded || frame != null) return child;
                        return ColoredBox(
                          color: appColors.mediaBackground,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        if (item.isVideo)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: state.isVideoReady ? 0 : 1,
                child: ColoredBox(
                  color: appColors.mediaBackground,
                  child: thumbnailPath != null
                      ? Image.file(
                          File(thumbnailPath),
                          key: ValueKey('thumbnail:${item.path}'),
                          fit: BoxFit.contain,
                          cacheWidth: 960,
                          errorBuilder: (_, _, _) =>
                              const _VideoLoadingPlaceholder(),
                        )
                      : const _VideoLoadingPlaceholder(),
                ),
              ),
            ),
          ),
        if (item.isVideo)
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: controlsVisible ? 1 : 0,
              child: IgnorePointer(
                ignoring: !controlsVisible,
                child: IconButton.filled(
                  tooltip: state.isPlaying ? 'Pause' : 'Play',
                  onPressed: togglePlayback,
                  style: IconButton.styleFrom(
                    backgroundColor: appColors.mediaOverlay,
                    foregroundColor: appColors.onMedia,
                    minimumSize: const Size.square(72),
                    iconSize: 42,
                  ),
                  icon: HugeIcon(
                    icon: state.isPlaying
                        ? HugeIcons.strokeRoundedPause
                        : HugeIcons.strokeRoundedPlay,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
        if (item.isVideo)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              offset: controlsVisible ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: controlsVisible ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !controlsVisible,
                  child: _VideoControls(
                    state: state,
                    onInteraction: onInteraction,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
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

class _VideoControls extends ConsumerWidget {
  const _VideoControls({required this.state, required this.onInteraction});
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
            '${_format(state.position)} / ${_format(state.duration)}',
            style: TextStyle(color: appColors.onMedia),
          ),
          IconButton(
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

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
