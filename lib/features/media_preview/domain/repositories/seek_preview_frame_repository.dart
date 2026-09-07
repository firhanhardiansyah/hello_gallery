import 'dart:typed_data';

import '../../../gallery/domain/entities/gallery_item.dart';

abstract interface class SeekPreviewFrameRepository {
  Future<SeekPreviewFrame?> getFrame(
    MediaItem item,
    Duration position, {
    int width = 320,
    bool precise = false,
  });
}

final class SeekPreviewFrame {
  const SeekPreviewFrame({
    required this.bytes,
    required this.requestedPosition,
    required this.actualPosition,
    required this.precise,
  });

  final Uint8List bytes;
  final Duration requestedPosition;
  final Duration actualPosition;
  final bool precise;
}
