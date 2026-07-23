import 'dart:io';

import 'package:flutter/material.dart';

import '../../../thumbnail/application/services/thumbnail_job_scheduler.dart';
import '../../domain/entities/gallery_item.dart';

final class GalleryMediaCacheInvalidator {
  const GalleryMediaCacheInvalidator({
    required this.thumbnailScheduler,
    required this.invalidateThumbnailProviders,
  });

  final ThumbnailJobScheduler thumbnailScheduler;
  final ValueChanged<MediaItem> invalidateThumbnailProviders;

  Future<void> call(MediaItem item) async {
    await Future.wait([
      FileImage(File(item.path)).evict(),
      thumbnailScheduler.invalidate(item),
    ]);
    invalidateThumbnailProviders(item);
  }
}
