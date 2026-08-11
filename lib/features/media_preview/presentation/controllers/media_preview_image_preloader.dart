import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../states/media_preview_ui_state.dart';

typedef MediaPreviewImagePrecache =
    Future<void> Function(MediaItem item, BuildContext context);

final class MediaPreviewImagePreloader {
  MediaPreviewImagePreloader({MediaPreviewImagePrecache? precache})
    : _precache = precache ?? _precacheFileImage;

  final MediaPreviewImagePrecache _precache;
  String? _scheduledWindowIdentity;
  int _generation = 0;

  void schedule(BuildContext context, MediaPreviewUiState state) {
    final items = _imageWindow(state);
    final identity = Object.hashAll([
      state.activeIndex,
      for (final item in items)
        Object.hash(item.path, item.modifiedAt, item.sizeBytes),
    ]).toString();
    if (_scheduledWindowIdentity == identity) return;
    _scheduledWindowIdentity = identity;
    final generation = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || generation != _generation) return;
      unawaited(_precacheWindow(context, items, generation));
    });
  }

  void dispose() {
    _generation++;
  }

  List<MediaItem> _imageWindow(MediaPreviewUiState state) {
    if (state.items.isEmpty) return const [];
    final result = <MediaItem>[];
    for (final index in [
      state.activeIndex,
      state.activeIndex - 1,
      state.activeIndex + 1,
    ]) {
      if (index < 0 || index >= state.items.length) continue;
      final item = state.items[index];
      if (!item.isVideo) result.add(item);
    }
    return result;
  }

  Future<void> _precacheWindow(
    BuildContext context,
    List<MediaItem> items,
    int generation,
  ) async {
    await Future.wait([
      for (final item in items)
        if (context.mounted && generation == _generation)
          _precacheItem(item, context),
    ]);
  }

  Future<void> _precacheItem(MediaItem item, BuildContext context) async {
    try {
      await _precache(item, context);
    } on Object catch (error) {
      debugPrint('Could not preload image ${item.path}: $error');
    }
  }

  static Future<void> _precacheFileImage(
    MediaItem item,
    BuildContext context,
  ) => precacheImage(
    FileImage(File(item.path)),
    context,
    onError: (error, _) {
      debugPrint('Could not preload image ${item.path}: $error');
    },
  );
}
