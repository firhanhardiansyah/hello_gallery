import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../application/use_cases/move_media_to_trash.dart';
import '../../domain/entities/gallery_item.dart';
import '../../domain/entities/media_move.dart';
import '../states/media_drag_payload.dart';
import '../widgets/folder_management/folder_management_dialogs.dart';
import '../widgets/media_grouping/group_media_dialog.dart';
import '../widgets/media_management/media_management_dialogs.dart';
import '../widgets/media_move/media_move_progress_dialog.dart';
import 'gallery_action_dependencies.dart';

typedef MoveGalleryMedia =
    Future<MediaMoveResult> Function({
      required List<MediaItem> items,
      required String destinationPath,
    });
typedef RenameGalleryMedia =
    Future<String> Function({
      required String rootPath,
      required String mediaPath,
      required String newBaseName,
    });
typedef TrashGalleryMedia =
    Future<MediaTrashResult> Function({
      required String rootPath,
      required List<MediaItem> items,
    });

final class GalleryMediaActions {
  const GalleryMediaActions({
    required this.runModal,
    required this.moveMedia,
    required this.renameMedia,
    required this.trashMedia,
    required this.syncDirectories,
    required this.clearFolderPreviewCache,
    required this.invalidateMediaCache,
    required this.notifyFolderTreeChanged,
    required this.removeSelectedPaths,
    required this.clearSelection,
  });

  final GalleryModalRunner runModal;
  final MoveGalleryMedia moveMedia;
  final RenameGalleryMedia renameMedia;
  final TrashGalleryMedia trashMedia;
  final Future<void> Function(Set<String> directoryPaths) syncDirectories;
  final VoidCallback clearFolderPreviewCache;
  final Future<void> Function(MediaItem item) invalidateMediaCache;
  final ValueChanged<Set<String>> notifyFolderTreeChanged;
  final ValueChanged<Iterable<String>> removeSelectedPaths;
  final VoidCallback clearSelection;

  Future<void> moveToFolder({
    required BuildContext context,
    required MediaDragPayload payload,
    required String destinationPath,
  }) async {
    final items = List<MediaItem>.unmodifiable(payload.items);
    if (items.isEmpty ||
        items.every(
          (item) => path.equals(path.dirname(item.path), destinationPath),
        )) {
      return;
    }

    final result = await runModal(() async {
      if (items.length > 1) {
        return showMediaMoveProgressDialog(
          context: context,
          items: items,
          destinationPath: destinationPath,
        );
      }
      return moveMedia(items: items, destinationPath: destinationPath);
    });
    if (!context.mounted || result == null) return;

    await Future.wait([
      for (final item in items) FileImage(File(item.path)).evict(),
    ]);
    clearFolderPreviewCache();
    final affectedPaths = {
      destinationPath,
      for (final item in items) path.dirname(item.path),
    };
    notifyFolderTreeChanged(affectedPaths);
    await syncDirectories(affectedPaths);
    if (!context.mounted) return;
    clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved ${result.moved}, skipped ${result.skipped}, '
          'failed ${result.failed}',
        ),
      ),
    );
  }

  Future<void> openGroupDialog({
    required BuildContext context,
    required String rootPath,
    required String currentPath,
  }) {
    return runModal(() async {
      await showGroupMediaDialog(
        context: context,
        rootPath: rootPath,
        currentDirectoryPath: currentPath,
      );
    });
  }

  Future<String?> rename({
    required BuildContext context,
    required String rootPath,
    required MediaItem item,
  }) async {
    return runModal(() async {
      String? newPath;
      final renamed = await showMediaNameDialog(
        context: context,
        locationPath: path.dirname(item.path),
        initialBaseName: path.basenameWithoutExtension(item.path),
        extension: item.extension,
        onSubmit: (newBaseName) async {
          newPath = await renameMedia(
            rootPath: rootPath,
            mediaPath: item.path,
            newBaseName: newBaseName,
          );
        },
      );
      final destination = newPath;
      if (!renamed || destination == null || !context.mounted) return null;
      if (path.equals(destination, item.path)) return destination;

      await invalidateMediaCache(item);
      final directoryPath = path.dirname(item.path);
      clearFolderPreviewCache();
      notifyFolderTreeChanged({directoryPath});
      await syncDirectories({directoryPath});
      if (!context.mounted) return destination;
      removeSelectedPaths([item.path]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renamed to ${path.basename(destination)}')),
      );
      return destination;
    });
  }

  Future<MediaTrashResult?> delete({
    required BuildContext context,
    required String rootPath,
    required List<MediaItem> items,
  }) async {
    if (items.isEmpty) return null;
    final uniqueItems = <String, MediaItem>{
      for (final item in items) path.normalize(item.path): item,
    }.values.toList(growable: false);

    return runModal(() async {
      final confirmed = await showMoveMediaToTrashDialog(
        context: context,
        mediaNames: [for (final item in uniqueItems) item.name],
      );
      if (!confirmed || !context.mounted) return null;
      final result = await runFolderOperationWithProgress(
        context: context,
        message: uniqueItems.length == 1
            ? 'Moving ${uniqueItems.single.name} to Trash...'
            : 'Moving ${uniqueItems.length} files to Trash...',
        operation: () => trashMedia(rootPath: rootPath, items: uniqueItems),
      );
      if (!context.mounted) return result;

      await Future.wait([
        for (final item in result.moved) invalidateMediaCache(item),
      ]);
      final affectedDirectories = {
        for (final item in result.moved) path.dirname(item.path),
      };
      if (affectedDirectories.isNotEmpty) {
        clearFolderPreviewCache();
        notifyFolderTreeChanged(affectedDirectories);
        await syncDirectories(affectedDirectories);
      }
      if (!context.mounted) return result;
      removeSelectedPaths(result.moved.map((item) => item.path));

      final movedCount = result.moved.length;
      final failedCount = result.failed.length;
      final message = failedCount == 0
          ? 'Moved $movedCount ${movedCount == 1 ? 'file' : 'files'} to Trash'
          : 'Moved $movedCount, failed $failedCount';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return result;
    });
  }
}
