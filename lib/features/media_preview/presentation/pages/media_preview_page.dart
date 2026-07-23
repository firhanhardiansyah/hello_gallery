import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/value_objects/gallery_sort.dart';

import '../input/media_preview_input_handler.dart';
import '../notifiers/media_preview_notifier.dart';
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
  late final MediaPreviewInputHandler _inputHandler;
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _controlsHiddenByNavigation = false;
  int _silentNavigationCount = 0;

  MediaPreviewNotifier get _controller =>
      ref.read(mediaPreviewNotifierProvider.notifier);

  @override
  void initState() {
    super.initState();
    _inputHandler = MediaPreviewInputHandler(
      onPrevious: () => _navigateWithoutRevealingControls(_controller.previous),
      onNext: () => _navigateWithoutRevealingControls(_controller.next),
      onSeekBackward: () => _seekBy(const Duration(seconds: -3)),
      onSeekForward: () => _seekBy(const Duration(seconds: 3)),
      onTogglePlay: _togglePlay,
      onToggleMute: _toggleMute,
      onRotate: _rotateActiveMedia,
      onToggleRotationLock: _toggleRotationLock,
      onToggleLoop: _toggleLoop,
      onToggleSidebar: _toggleSidebar,
      onToggleFullscreen: _toggleFullscreen,
      onClose: () => widget.onClose?.call(),
      onEscape: _handleEscape,
      onRequestFocus: _focusNode.requestFocus,
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
    _hideTimer?.cancel();
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

  void _toggleSidebar() => widget.onToggleSidebar?.call();

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

  void _seekBy(Duration delta) {
    _showControls(userInitiated: true);
    unawaited(_controller.seekBy(delta));
  }

  void _handleEscape() {
    if (widget.isFullscreen) {
      _toggleFullscreen();
      return;
    }
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _navigateWithoutRevealingControls(Future<void> Function() navigate) {
    _suppressControlsDuringNavigation();
    unawaited(navigate());
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaPreviewNotifierProvider);
    final rotationQuarterTurns = state.rotationFor(state.activeItem?.path);
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
        onPointerSignal: _inputHandler.handlePointerSignal,
        child: MouseRegion(
          cursor: state.isPlaying && !_controlsVisible
              ? SystemMouseCursors.none
              : MouseCursor.defer,
          onEnter: (_) => _showControls(userInitiated: true),
          onHover: (_) => _showControls(userInitiated: true),
          child: MediaPreviewView(
            state: state,
            controlsVisible: _controlsVisible,
            isFullscreen: widget.isFullscreen,
            rotationQuarterTurns: rotationQuarterTurns,
            isRotationLocked: state.isRotationLocked,
            onInteraction: () => _showControls(userInitiated: true),
            onRotate: _rotateActiveMedia,
            onToggleRotationLock: _toggleRotationLock,
            onToggleFullscreen: _toggleFullscreen,
          ),
        ),
      ),
    );
  }
}
