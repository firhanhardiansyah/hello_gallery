import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../widgets/folder_management/folder_management_dialogs.dart';
import 'gallery_action_dependencies.dart';

typedef CreateGalleryFolder =
    Future<String> Function({
      required String rootPath,
      required String parentPath,
      required String folderName,
    });
typedef RenameGalleryFolder =
    Future<String> Function({
      required String rootPath,
      required String folderPath,
      required String newName,
    });
typedef TrashGalleryFolder =
    Future<void> Function({
      required String rootPath,
      required String folderPath,
    });

final class GalleryFolderActions {
  const GalleryFolderActions({
    required this.runModal,
    required this.createFolder,
    required this.renameFolder,
    required this.trashFolder,
    required this.refreshGallery,
    required this.reconcileRenamedFolder,
    required this.reconcileTrashedFolder,
    required this.isPreviewPathInside,
    required this.closePreview,
    required this.notifyFolderTreeChanged,
  });

  final GalleryModalRunner runModal;
  final CreateGalleryFolder createFolder;
  final RenameGalleryFolder renameFolder;
  final TrashGalleryFolder trashFolder;
  final Future<void> Function() refreshGallery;
  final Future<void> Function({
    required String oldPath,
    required String newPath,
  })
  reconcileRenamedFolder;
  final Future<void> Function(String folderPath) reconcileTrashedFolder;
  final bool Function(String folderPath) isPreviewPathInside;
  final Future<void> Function() closePreview;
  final ValueChanged<Set<String>> notifyFolderTreeChanged;

  Future<void> create({
    required BuildContext context,
    required String rootPath,
    required String currentPath,
  }) async {
    await runModal(() async {
      final created = await showFolderNameDialog(
        context: context,
        title: 'Create folder',
        locationPath: currentPath,
        submitLabel: 'Create folder',
        onSubmit: (folderName) => createFolder(
          rootPath: rootPath,
          parentPath: currentPath,
          folderName: folderName,
        ),
      );
      if (!created || !context.mounted) return;
      notifyFolderTreeChanged({currentPath});
      await refreshGallery();
    });
  }

  Future<void> rename({
    required BuildContext context,
    required String rootPath,
    required String folderPath,
  }) async {
    if (path.equals(rootPath, folderPath)) return;
    await runModal(() async {
      String? newPath;
      final renamed = await showFolderNameDialog(
        context: context,
        title: 'Rename folder',
        locationPath: path.dirname(folderPath),
        initialName: path.basename(folderPath),
        submitLabel: 'Rename',
        onSubmit: (newName) async {
          newPath = await renameFolder(
            rootPath: rootPath,
            folderPath: folderPath,
            newName: newName,
          );
        },
      );
      final destination = newPath;
      if (!renamed || destination == null || !context.mounted) return;
      if (path.equals(destination, folderPath)) return;
      if (isPreviewPathInside(folderPath)) await closePreview();
      notifyFolderTreeChanged({path.dirname(folderPath)});
      await reconcileRenamedFolder(oldPath: folderPath, newPath: destination);
    });
  }

  Future<void> delete({
    required BuildContext context,
    required String rootPath,
    required String folderPath,
  }) async {
    if (path.equals(rootPath, folderPath)) return;
    await runModal(() async {
      final confirmed = await showMoveFolderToTrashDialog(
        context: context,
        folderName: path.basename(folderPath),
      );
      if (!confirmed || !context.mounted) return;
      try {
        await runFolderOperationWithProgress<void>(
          context: context,
          message: 'Moving ${path.basename(folderPath)} to Trash...',
          operation: () =>
              trashFolder(rootPath: rootPath, folderPath: folderPath),
        );
      } on Object catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(folderOperationErrorMessage(error))),
        );
        return;
      }
      if (!context.mounted) return;
      if (isPreviewPathInside(folderPath)) await closePreview();
      notifyFolderTreeChanged({path.dirname(folderPath)});
      await reconcileTrashedFolder(folderPath);
    });
  }
}
