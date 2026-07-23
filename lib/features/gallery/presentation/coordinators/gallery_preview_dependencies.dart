import '../../domain/entities/gallery_item.dart';

typedef ReadGalleryEntries = Future<List<GalleryItem>> Function(String path);
typedef GalleryMountedReader = bool Function();
