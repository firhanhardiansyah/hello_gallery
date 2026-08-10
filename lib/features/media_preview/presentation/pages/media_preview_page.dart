import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';

import '../../application/providers/media_preview_dependencies.dart';
import '../constants/media_preview_timing.dart';
import '../controllers/media_preview_overlay_controller.dart';
import '../input/media_preview_input_handler.dart';
import '../notifiers/media_preview_notifier.dart';
import '../widgets/filmstrip/media_preview_filmstrip_controller.dart';
import '../widgets/media_preview_pointer_region.dart';
import '../widgets/media_preview_view.dart';

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
    this.onToggleTopBar,
    this.onControlsVisibilityChanged,
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
  final VoidCallback? onToggleTopBar;
  final ValueChanged<bool>? onControlsVisibilityChanged;
  final VoidCallback? onClose;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;

  @override
  ConsumerState<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends ConsumerState<MediaPreviewPage> {
  final _focusNode = FocusNode();
  final _filmstripController = MediaPreviewFilmstripController();
  late final MediaPreviewInputHandler _inputHandler;
  late final MediaPreviewOverlayController _overlayController;
  int? _filmstripNavigationTargetIndex;

  MediaPreviewNotifier get _controller =>
      ref.read(mediaPreviewNotifierProvider.notifier);

  @override
  void initState() {
    super.initState();
    _overlayController = MediaPreviewOverlayController(
      readPreviewState: () => ref.read(mediaPreviewNotifierProvider),
      onVisibilityChanged: widget.onControlsVisibilityChanged,
    )..addListener(_handleOverlayChanged);
    _inputHandler = MediaPreviewInputHandler(
      onPrevious: () => _navigateHidingControls(_controller.previous),
      onNext: () => _navigateHidingControls(_controller.next),
      onSeekBackward: () => _seekBy(MediaPreviewTiming.seekBackwardStep),
      onSeekForward: () => _seekBy(MediaPreviewTiming.seekForwardStep),
      onTogglePlay: _togglePlay,
      onToggleMute: _toggleMute,
      onRotate: _rotateActiveMedia,
      onToggleRotationLock: _toggleRotationLock,
      onToggleLoop: _toggleLoop,
      onToggleFilmstrip: _toggleFilmstrip,
      onToggleSidebar: _toggleSidebar,
      onToggleTopBar: _toggleTopBar,
      onToggleFullscreen: _toggleFullscreen,
      onClose: _closePreview,
      onEscape: _closePreview,
      onRequestFocus: _focusNode.requestFocus,
      onGamepadInteraction: _scheduleGamepadAutoHide,
    )..start();
    Future.microtask(() async {
      if (!mounted) return;
      await _controller.configure(widget.items, widget.initialIndex);
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputHandler.dispose();
    _filmstripController.dispose();
    _overlayController
      ..removeListener(_handleOverlayChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleOverlayChanged() {
    if (mounted) setState(() {});
  }

  void _showControls({bool restartTimer = true, bool userInitiated = false}) {
    _overlayController.showControls(
      restartTimer: restartTimer,
      userInitiated: userInitiated,
    );
  }

  void _setControlsHovered(bool hovered) =>
      _overlayController.setControlsHovered(hovered);

  void _hideControlsAfterPreviewExit() =>
      _overlayController.hideAfterPointerExit();

  void _scheduleGamepadAutoHide() =>
      _overlayController.scheduleGamepadAutoHide();

  void _toggleSidebar() => widget.onToggleSidebar?.call();

  void _toggleTopBar() => widget.onToggleTopBar?.call();

  void _toggleFullscreen() => widget.onToggleFullscreen?.call();

  void _rotateActiveMedia() {
    final activePath = ref.read(mediaPreviewNotifierProvider).activeItem?.path;
    if (activePath == null) return;
    _showControls(userInitiated: true);
    _controller.rotateActiveMedia();
  }

  void _toggleRotationLock() {
    final activePath = ref.read(mediaPreviewNotifierProvider).activeItem?.path;
    if (activePath == null) return;
    _showControls(userInitiated: true);
    _controller.toggleRotationLock();
  }

  void _togglePlay() {
    _showControls(userInitiated: true);
    unawaited(_controller.togglePlay());
  }

  void _toggleMute() {
    _showControls(userInitiated: true);
    unawaited(_controller.toggleMute());
  }

  void _toggleLoop() {
    if (ref.read(mediaPreviewNotifierProvider).activeItem?.isVideo != true) {
      return;
    }
    _showControls(userInitiated: true);
    unawaited(_controller.toggleLoop());
  }

  void _toggleFilmstrip() {
    _showControls(userInitiated: true);
    final showFilmstrip = _overlayController.toggleFilmstrip();
    if (!showFilmstrip) return;
    final activeIndex = ref.read(mediaPreviewNotifierProvider).activeIndex;
    _filmstripController.reveal(activeIndex, animated: false, force: true);
  }

  void _toggleHdrPlayback() {
    _showControls(userInitiated: true);
    ref.read(mediaPlaybackConfigProvider.notifier).toggleHdr();
    unawaited(_controller.applyPlaybackColorConfig());
  }

  void _selectFromFilmstrip(int index) {
    _filmstripNavigationTargetIndex = index;
    _showControls(userInitiated: true);
    unawaited(_selectMediaFromFilmstrip(index));
  }

  Future<void> _selectMediaFromFilmstrip(int index) async {
    try {
      await _controller.select(index);
    } finally {
      if (_filmstripNavigationTargetIndex == index) {
        _filmstripNavigationTargetIndex = null;
      }
      if (mounted) {
        _showControls(userInitiated: true);
      }
    }
  }

  void _seekBy(Duration delta) {
    _showControls(userInitiated: true);
    unawaited(_controller.seekBy(delta));
  }

  void _closePreview() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _navigateHidingControls(Future<void> Function() navigate) {
    unawaited(_overlayController.navigateWithoutControls(navigate));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaPreviewNotifierProvider);
    final hdrPlaybackEnabled = ref.watch(
      mediaPlaybackConfigProvider.select((config) => config.hdrEnabled),
    );
    final rotationQuarterTurns = state.rotationFor(state.activeItem?.path);
    ref.listen(
      mediaPreviewNotifierProvider.select((value) => value.activeIndex),
      (previous, activeIndex) {
        if (previous != activeIndex) {
          if (_filmstripNavigationTargetIndex == activeIndex) {
            _showControls(userInitiated: true);
            return;
          }
          if (!_overlayController.isManualNavigationRunning) {
            _overlayController.suppressControlsDuringNavigation();
          }
        }
      },
    );
    ref.listen(
      mediaPreviewNotifierProvider.select((value) => value.isPlaying),
      (previous, isPlaying) {
        if (_overlayController.isNavigationEventSuppressed) return;
        if (isPlaying) {
          _showControls();
        } else {
          _showControls(restartTimer: false);
        }
      },
    );
    final isVideoPreview = state.activeItem?.isVideo == true;
    final filmstripVisible =
        _overlayController.filmstripEnabled &&
        (!isVideoPreview || _overlayController.controlsVisible);
    if (filmstripVisible && state.items.isNotEmpty) {
      _filmstripController.reveal(state.activeIndex, animated: false);
    }
    return Focus(
      focusNode: _focusNode,
      child: Listener(
        onPointerSignal: _inputHandler.handlePointerSignal,
        child: MediaPreviewPointerRegion(
          cursor: state.isPlaying && !_overlayController.controlsVisible
              ? SystemMouseCursors.none
              : MouseCursor.defer,
          onActivity: () => _showControls(userInitiated: true),
          onExitIdle: _hideControlsAfterPreviewExit,
          child: MediaPreviewView(
            state: state,
            controlsVisible: _overlayController.controlsVisible,
            isFullscreen: widget.isFullscreen,
            rotationQuarterTurns: rotationQuarterTurns,
            isRotationLocked: state.isRotationLocked,
            filmstripVisible: filmstripVisible,
            hdrPlaybackEnabled: hdrPlaybackEnabled,
            filmstripController: _filmstripController,
            onInteraction: () => _showControls(userInitiated: true),
            onTogglePlayback: _togglePlay,
            onControlsHoverChanged: _setControlsHovered,
            onRotate: _rotateActiveMedia,
            onToggleRotationLock: _toggleRotationLock,
            onToggleFilmstrip: _toggleFilmstrip,
            onToggleHdrPlayback: _toggleHdrPlayback,
            onSelectMedia: _selectFromFilmstrip,
            onToggleFullscreen: _toggleFullscreen,
          ),
        ),
      ),
    );
  }
}
