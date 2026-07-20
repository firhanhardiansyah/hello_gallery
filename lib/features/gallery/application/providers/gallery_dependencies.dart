import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/local_gallery_data_source.dart';
import '../../data/repositories/gallery_repository_impl.dart';
import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../services/folder_preview_cache.dart';
import '../services/folder_preview_job_scheduler.dart';
import '../services/gallery_directory_cache.dart';
import '../use_cases/find_folder_preview_media.dart';
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

final findFolderPreviewMediaProvider = Provider(
  (ref) => FindFolderPreviewMedia(ref.watch(galleryRepositoryProvider)),
);

final folderPreviewCacheProvider = Provider((ref) => FolderPreviewCache());

final folderPreviewJobSchedulerProvider = Provider(
  (ref) => FolderPreviewJobScheduler(
    ref.watch(findFolderPreviewMediaProvider),
    ref.watch(folderPreviewCacheProvider),
  ),
);

final folderPreviewProvider = FutureProvider.autoDispose
    .family<List<MediaItem>, GalleryFolder>((ref, folder) async {
      final scheduler = ref.read(folderPreviewJobSchedulerProvider);
      FolderPreviewRequest? activeRequest;
      var disposed = false;
      ref.onDispose(() {
        disposed = true;
        activeRequest?.cancel();
      });

      while (!disposed) {
        final request = scheduler.getPreview(folder);
        activeRequest = request;
        final previews = await request.result;
        if (!request.wasCancelled) return previews;
        if (disposed) break;
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return const [];
    });
