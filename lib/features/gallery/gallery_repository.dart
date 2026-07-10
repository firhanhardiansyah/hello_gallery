import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/gallery_item.dart';
import 'gallery_service.dart';

final galleryRepositoryProvider = Provider(
  (ref) => GalleryRepository(ref.watch(galleryServiceProvider)),
);

class GalleryRepository {
  const GalleryRepository(this._service);

  final GalleryService _service;

  Future<List<GalleryItem>> readDirectory(String path) => _service.scan(path);
}
