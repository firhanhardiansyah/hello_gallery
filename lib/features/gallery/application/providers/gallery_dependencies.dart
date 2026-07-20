import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/local_gallery_data_source.dart';
import '../../data/repositories/gallery_repository_impl.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../services/gallery_directory_cache.dart';
import '../use_cases/read_gallery_directory.dart';
import '../use_cases/read_media_recursively.dart';

final localGalleryDataSourceProvider = Provider(
  (ref) => const LocalGalleryDataSource(),
);

final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => GalleryRepositoryImpl(ref.watch(localGalleryDataSourceProvider)),
);

final galleryDirectoryCacheProvider = Provider(
  (ref) => GalleryDirectoryCache(),
);

final readGalleryDirectoryProvider = Provider(
  (ref) => ReadGalleryDirectory(
    ref.watch(galleryRepositoryProvider),
    ref.watch(galleryDirectoryCacheProvider),
  ),
);

final readMediaRecursivelyProvider = Provider(
  (ref) => ReadMediaRecursively(ref.watch(galleryRepositoryProvider)),
);
