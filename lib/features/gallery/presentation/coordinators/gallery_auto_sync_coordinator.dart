import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../media_index/domain/entities/file_change.dart';
import '../../application/services/folder_preview_job_scheduler.dart';
import '../../domain/entities/gallery_item.dart';
import '../../domain/rules/gallery_item_sort_rules.dart';
import '../../domain/value_objects/gallery_sort.dart';
import '../states/gallery_ui_state.dart';
import '../states/media_preview_selection.dart';
import 'gallery_preview_dependencies.dart';

typedef SyncGalleryDirectories =
    Future<void> Function(
      Set<String> directoryPaths, {
      Set<String> removedPaths,
    });

final class GalleryAutoSyncCoordinator {
  GalleryAutoSyncCoordinator({
    required this.folderPreviewScheduler,
    required this.readGallery,
    required this.readSort,
    required this.readDirectory,
    required this.readPreview,
    required this.updatePreview,
    required this.reconcileMediaPreview,
    required this.readActiveMedia,
    required this.syncDirectories,
    required this.invalidateFolderPreview,
    required this.notifyFolderTreeChanged,
    required this.closePreview,
    required this.openPreviewRoute,
    required this.readRoutePreviewPath,
    required this.isMounted,
  });

  final FolderPreviewJobScheduler folderPreviewScheduler;
  final GalleryUiState Function() readGallery;
  final GallerySort Function() readSort;
  final ReadGalleryEntries readDirectory;
  final MediaPreviewSelection? Function() readPreview;
  final void Function(MediaPreviewSelection preview) updatePreview;
  final Future<bool> Function(List<MediaItem> items) reconcileMediaPreview;
  final MediaItem? Function() readActiveMedia;
  final SyncGalleryDirectories syncDirectories;
  final void Function(GalleryFolder folder) invalidateFolderPreview;
  final ValueChanged<Set<String>> notifyFolderTreeChanged;
  final Future<void> Function() closePreview;
  final void Function(String mediaPath) openPreviewRoute;
  final String? Function() readRoutePreviewPath;
  final GalleryMountedReader isMounted;

  int _generation = 0;

  Future<void> handle(FileChangeBatch batch) async {
    final generation = ++_generation;
    final gallery = readGallery();
    _invalidateFolderPreviews(batch, gallery);
    await _evictChangedImages(batch);
    if (!isMounted()) return;

    notifyFolderTreeChanged(batch.affectedDirectoryPaths);
    await syncDirectories(
      batch.affectedDirectoryPaths,
      removedPaths: {
        for (final change in batch.changes)
          if (change.type == FileChangeType.removed) change.path,
      },
    );
    final preview = readPreview();
    if (!isMounted() || generation != _generation || preview == null) return;
    if (!_previewFolderChanged(batch, preview)) return;
    await _reconcilePreview(preview, generation);
  }

  void _invalidateFolderPreviews(
    FileChangeBatch batch,
    GalleryUiState gallery,
  ) {
    final rootPath = gallery.rootPath;
    if (rootPath != null) {
      for (final directoryPath in batch.affectedDirectoryPaths) {
        var ancestorPath = directoryPath;
        while (path.equals(rootPath, ancestorPath) ||
            path.isWithin(rootPath, ancestorPath)) {
          folderPreviewScheduler.invalidate(ancestorPath);
          if (path.equals(rootPath, ancestorPath)) break;
          final parentPath = path.dirname(ancestorPath);
          if (path.equals(parentPath, ancestorPath)) break;
          ancestorPath = parentPath;
        }
      }
    }
    for (final folder in gallery.items.whereType<GalleryFolder>()) {
      final containsChangedPath = batch.changes.any(
        (change) =>
            path.equals(folder.path, change.path) ||
            path.isWithin(folder.path, change.path),
      );
      if (!containsChangedPath) continue;
      folderPreviewScheduler.invalidate(folder.path);
      invalidateFolderPreview(folder);
    }
  }

  Future<void> _evictChangedImages(FileChangeBatch batch) {
    return Future.wait([
      for (final change in batch.changes)
        if (change.type != FileChangeType.added)
          FileImage(File(change.path)).evict(),
    ]);
  }

  bool _previewFolderChanged(
    FileChangeBatch batch,
    MediaPreviewSelection preview,
  ) {
    return batch.affectedDirectoryPaths.any(
      (directoryPath) => path.equals(directoryPath, preview.folderPath),
    );
  }

  Future<void> _reconcilePreview(
    MediaPreviewSelection preview,
    int generation,
  ) async {
    try {
      final media =
          (await readDirectory(
            preview.folderPath,
          )).whereType<MediaItem>().toList()..sort(
            (a, b) => GalleryItemSortRules.compareMedia(a, b, readSort()),
          );
      if (!isMounted() || generation != _generation) return;
      final hasMedia = await reconcileMediaPreview(media);
      if (!isMounted() || generation != _generation) return;
      if (!hasMedia) {
        await closePreview();
        return;
      }

      final activeItem = readActiveMedia();
      if (activeItem == null) return;
      final activeIndex = media.indexWhere(
        (item) => path.equals(item.path, activeItem.path),
      );
      updatePreview(
        MediaPreviewSelection(
          items: media,
          initialIndex: activeIndex,
          folderPath: preview.folderPath,
          requestedMediaPath: activeItem.path,
        ),
      );
      if (!path.equals(readRoutePreviewPath() ?? '', activeItem.path)) {
        openPreviewRoute(activeItem.path);
      }
    } on Object {
      // Keep the current preview while a file operation is still settling.
    }
  }
}
