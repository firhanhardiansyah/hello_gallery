import 'dart:typed_data';

import '../../../gallery/domain/entities/gallery_item.dart';

abstract interface class SeekPreviewFrameRepository {
  Future<Uint8List?> getFrame(
    MediaItem item,
    Duration position, {
    int width = 320,
    bool precise = false,
  });
}
