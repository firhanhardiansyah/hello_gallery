import 'package:flutter/widgets.dart';

import '../widgets/gallery_page/gallery_body.dart';
import 'gallery_shell_scope.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bindings = GalleryShellScope.of(context).galleryPage;
    final gallery = bindings.gallery;
    final selection = bindings.selection;

    return GalleryBody(
      state: gallery,
      scrollController: bindings.scrollController,
      selectedIndex: selection.selectedIndex,
      keyboardFocusVisible: selection.keyboardFocusVisible,
      showItemNames: bindings.settings.showItemNames,
      layoutMode: bindings.settings.galleryLayoutMode,
      maxCrossAxisExtent: bindings.settings.galleryItemExtent,
      selectedPaths: selection.selectedPaths,
      onSelectionChanged: bindings.onSelectionChanged,
      onClearSelection: bindings.onClearSelection,
      onColumnCountChanged: bindings.onColumnCountChanged,
      onFolderSelected: bindings.onFolderSelected,
      onRenameFolder: bindings.onRenameFolder,
      onDeleteFolder: bindings.onDeleteFolder,
      onRenameMedia: bindings.onRenameMedia,
      onDeleteMedia: bindings.onDeleteMedia,
      onMediaDropped: bindings.onMediaDropped,
      onMediaSelected: bindings.onMediaSelected,
    );
  }
}
