import 'package:flutter/material.dart';

import '../../../gallery/presentation/pages/gallery_shell_scope.dart';
import 'media_preview_page.dart';

class MediaPreviewRoutePage extends StatelessWidget {
  const MediaPreviewRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bindings = GalleryShellScope.of(context).mediaPreviewPage;
    final selection = bindings.selection;
    if (selection == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MediaPreviewPage(
      key: ValueKey(selection.requestedMediaPath),
      items: selection.items,
      initialIndex: selection.initialIndex,
      rootPath: bindings.rootPath,
      currentFolderPath: selection.folderPath,
      sort: bindings.gallery.sort,
      embedded: true,
      sidebarVisible: bindings.sidebarVisible,
      onToggleSidebar: bindings.onToggleSidebar,
      onToggleTopBar: bindings.onToggleTopBar,
      onControlsVisibilityChanged: bindings.onControlsVisibilityChanged,
      onClose: bindings.onClose,
      isFullscreen: bindings.isFullscreen,
      onToggleFullscreen: bindings.onToggleFullscreen,
    );
  }
}
