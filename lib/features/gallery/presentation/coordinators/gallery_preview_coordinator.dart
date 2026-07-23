import 'package:path/path.dart' as path;

import '../../domain/entities/gallery_item.dart';
import '../../domain/rules/gallery_item_sort_rules.dart';
import '../../domain/value_objects/gallery_sort.dart';
import '../states/media_preview_selection.dart';
import 'gallery_preview_dependencies.dart';

final class GalleryPreviewCoordinator {
  GalleryPreviewCoordinator({
    required this.readDirectory,
    required this.readSort,
    required this.readPreview,
    required this.updatePreview,
    required this.isMounted,
    required this.openPreviewRoute,
    required this.closePreviewRoute,
    required this.showOpenError,
  });

  final ReadGalleryEntries readDirectory;
  final GallerySort Function() readSort;
  final MediaPreviewSelection? Function() readPreview;
  final void Function(MediaPreviewSelection? preview) updatePreview;
  final GalleryMountedReader isMounted;
  final void Function(String mediaPath) openPreviewRoute;
  final void Function() closePreviewRoute;
  final void Function(Object error) showOpenError;

  int _loadGeneration = 0;

  void open(MediaItem item) => openPreviewRoute(item.path);

  Future<void> close() async => closePreviewRoute();

  Future<void> syncRoute(String? mediaPath) async {
    final generation = ++_loadGeneration;
    if (mediaPath == null) {
      if (readPreview() != null && isMounted()) updatePreview(null);
      return;
    }
    if (readPreview()?.requestedMediaPath == mediaPath) return;
    await _load(mediaPath, generation);
  }

  Future<void> _load(String mediaPath, int generation) async {
    try {
      final media =
          (await readDirectory(
            path.dirname(mediaPath),
          )).whereType<MediaItem>().toList()..sort(
            (a, b) => GalleryItemSortRules.compareMedia(a, b, readSort()),
          );
      final initialIndex = media.indexWhere(
        (entry) => path.equals(entry.path, mediaPath),
      );
      if (!isMounted() || generation != _loadGeneration || initialIndex < 0) {
        return;
      }
      updatePreview(
        MediaPreviewSelection(
          items: media,
          initialIndex: initialIndex,
          folderPath: path.dirname(mediaPath),
          requestedMediaPath: mediaPath,
        ),
      );
    } on Object catch (error) {
      if (isMounted()) showOpenError(error);
    }
  }
}
