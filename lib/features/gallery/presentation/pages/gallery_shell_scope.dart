import 'package:flutter/widgets.dart';

import '../../domain/entities/gallery_item.dart';
import '../../../settings/presentation/states/settings_ui_state.dart';
import '../states/gallery_selection_state.dart';
import '../states/gallery_ui_state.dart';
import '../states/media_drag_payload.dart';
import '../states/media_preview_selection.dart';

typedef GalleryItemSelectionChanged =
    void Function(int index, {required bool toggle, required bool extend});

final class GalleryPageBindings {
  const GalleryPageBindings({
    required this.gallery,
    required this.settings,
    required this.selection,
    required this.scrollController,
    required this.onSelectionChanged,
    required this.onClearSelection,
    required this.onColumnCountChanged,
    required this.onFolderSelected,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onRenameMedia,
    required this.onDeleteMedia,
    required this.onMediaDropped,
    required this.onMediaSelected,
  });

  final GalleryUiState gallery;
  final SettingsUiState settings;
  final GallerySelectionState selection;
  final ScrollController scrollController;
  final GalleryItemSelectionChanged onSelectionChanged;
  final VoidCallback onClearSelection;
  final ValueChanged<int> onColumnCountChanged;
  final ValueChanged<String> onFolderSelected;
  final ValueChanged<String> onRenameFolder;
  final ValueChanged<String> onDeleteFolder;
  final ValueChanged<MediaItem> onRenameMedia;
  final ValueChanged<List<MediaItem>> onDeleteMedia;
  final void Function(MediaDragPayload payload, String destinationPath)
  onMediaDropped;
  final ValueChanged<MediaItem> onMediaSelected;
}

final class MediaPreviewPageBindings {
  const MediaPreviewPageBindings({
    required this.selection,
    required this.rootPath,
    required this.gallery,
    required this.sidebarVisible,
    required this.isFullscreen,
    required this.onToggleSidebar,
    required this.onToggleTopBar,
    required this.onControlsVisibilityChanged,
    required this.onClose,
    required this.onToggleFullscreen,
  });

  final MediaPreviewSelection? selection;
  final String rootPath;
  final GalleryUiState gallery;
  final bool sidebarVisible;
  final bool isFullscreen;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleTopBar;
  final ValueChanged<bool> onControlsVisibilityChanged;
  final VoidCallback onClose;
  final VoidCallback onToggleFullscreen;
}

class GalleryShellScope extends InheritedWidget {
  const GalleryShellScope({
    required this.galleryPage,
    required this.mediaPreviewPage,
    required super.child,
    super.key,
  });

  final GalleryPageBindings galleryPage;
  final MediaPreviewPageBindings mediaPreviewPage;

  static GalleryShellScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GalleryShellScope>();
    assert(
      scope != null,
      'GalleryShellScope was not found in the widget tree.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(GalleryShellScope oldWidget) =>
      galleryPage.gallery != oldWidget.galleryPage.gallery ||
      galleryPage.settings != oldWidget.galleryPage.settings ||
      galleryPage.selection != oldWidget.galleryPage.selection ||
      mediaPreviewPage.selection != oldWidget.mediaPreviewPage.selection ||
      mediaPreviewPage.sidebarVisible !=
          oldWidget.mediaPreviewPage.sidebarVisible ||
      mediaPreviewPage.isFullscreen != oldWidget.mediaPreviewPage.isFullscreen;
}
