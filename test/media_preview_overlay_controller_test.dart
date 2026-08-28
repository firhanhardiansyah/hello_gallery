import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/media_preview/presentation/controllers/media_preview_overlay_controller.dart';
import 'package:hello_gallery/features/media_preview/presentation/states/media_preview_ui_state.dart';

void main() {
  test('suppresses controls during navigation until user interaction', () {
    final visibilityChanges = <bool>[];
    final controller = MediaPreviewOverlayController(
      readPreviewState: _playingVideoState,
      onVisibilityChanged: visibilityChanges.add,
    );
    addTearDown(controller.dispose);

    controller.suppressControlsDuringNavigation();
    expect(controller.controlsVisible, isFalse);

    controller.showControls();
    expect(controller.controlsVisible, isFalse);

    controller.showControls(userInitiated: true);
    expect(controller.controlsVisible, isTrue);
    expect(visibilityChanges, [false, true]);
  });

  test('keeps controls visible while they are hovered', () async {
    final controller = MediaPreviewOverlayController(
      readPreviewState: _playingVideoState,
      autoHideDuration: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);
    controller.setControlsHovered(true);
    controller.showControls();

    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(controller.controlsVisible, isTrue);

    controller.setControlsHovered(false);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(controller.controlsVisible, isFalse);
  });

  test('toggles filmstrip independently from control visibility', () {
    final controller = MediaPreviewOverlayController(
      readPreviewState: _playingVideoState,
    );
    addTearDown(controller.dispose);

    expect(controller.toggleFilmstrip(), isFalse);
    controller.hideAfterPointerExit();
    expect(controller.toggleFilmstrip(), isTrue);
    expect(controller.controlsVisible, isFalse);
  });

  test('restores and synchronizes persisted filmstrip visibility', () {
    final controller = MediaPreviewOverlayController(
      readPreviewState: _playingVideoState,
      filmstripEnabled: false,
    );
    addTearDown(controller.dispose);

    expect(controller.filmstripEnabled, isFalse);
    controller.setFilmstripEnabled(true);
    expect(controller.filmstripEnabled, isTrue);
  });

  test('clean preview suppresses activity and restores prior visibility', () {
    final visibilityChanges = <bool>[];
    final controller = MediaPreviewOverlayController(
      readPreviewState: _playingVideoState,
      onVisibilityChanged: visibilityChanges.add,
    );
    addTearDown(controller.dispose);

    controller.setCleanPreviewEnabled(true);
    expect(controller.cleanPreviewEnabled, isTrue);
    expect(controller.controlsVisible, isFalse);

    controller.showControls(userInitiated: true);
    expect(controller.controlsVisible, isFalse);

    controller.setCleanPreviewEnabled(false);
    expect(controller.cleanPreviewEnabled, isFalse);
    expect(controller.controlsVisible, isTrue);
    expect(visibilityChanges, [false, true]);
  });

  test('clean preview preserves controls that were already hidden', () {
    final controller = MediaPreviewOverlayController(
      readPreviewState: _playingVideoState,
    );
    addTearDown(controller.dispose);

    controller.hideAfterPointerExit();
    controller.setCleanPreviewEnabled(true);
    controller.setCleanPreviewEnabled(false);

    expect(controller.controlsVisible, isFalse);
  });
}

MediaPreviewUiState _playingVideoState() => MediaPreviewUiState(
  items: [
    MediaItem(
      path: '/gallery/video.mp4',
      name: 'video.mp4',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.video,
    ),
  ],
  isPlaying: true,
);
