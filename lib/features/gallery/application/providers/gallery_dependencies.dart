import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/local_gallery_data_source.dart';
import '../../data/data_sources/local_folder_management_data_source.dart';
import '../../data/data_sources/local_media_organization_data_source.dart';
import '../../data/repositories/folder_management_repository_impl.dart';
import '../../data/repositories/gallery_repository_impl.dart';
import '../../data/repositories/media_organization_repository_impl.dart';
import '../../data/services/platform_folder_trash.dart';
import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../../domain/repositories/folder_management_repository.dart';
import '../../domain/repositories/media_organization_repository.dart';
import '../services/folder_preview_cache.dart';
import '../services/folder_preview_job_scheduler.dart';
import '../services/gallery_directory_cache.dart';
import '../use_cases/find_folder_preview_media.dart';
import '../use_cases/create_folder.dart';
import '../use_cases/move_folder_to_trash.dart';
import '../use_cases/move_media_items.dart';
import '../use_cases/read_gallery_directory.dart';
import '../use_cases/read_media_recursively.dart';
import '../use_cases/move_media_to_group.dart';
import '../use_cases/rename_folder.dart';
import '../use_cases/validate_media_group.dart';

final localGalleryDataSourceProvider = Provider(
  (ref) => const LocalGalleryDataSource(),
);

final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => GalleryRepositoryImpl(ref.watch(localGalleryDataSourceProvider)),
);

final platformFolderTrashProvider = Provider(
  (ref) => const PlatformFolderTrash(),
);

final localFolderManagementDataSourceProvider = Provider(
  (ref) =>
      LocalFolderManagementDataSource(ref.watch(platformFolderTrashProvider)),
);

final folderManagementRepositoryProvider = Provider<FolderManagementRepository>(
  (ref) => FolderManagementRepositoryImpl(
    ref.watch(localFolderManagementDataSourceProvider),
  ),
);

final createFolderProvider = Provider(
  (ref) => CreateFolder(ref.watch(folderManagementRepositoryProvider)),
);

final renameFolderProvider = Provider(
  (ref) => RenameFolder(ref.watch(folderManagementRepositoryProvider)),
);

final moveFolderToTrashProvider = Provider(
  (ref) => MoveFolderToTrash(ref.watch(folderManagementRepositoryProvider)),
);

final localMediaOrganizationDataSourceProvider = Provider(
  (ref) => const LocalMediaOrganizationDataSource(),
);

final mediaOrganizationRepositoryProvider =
    Provider<MediaOrganizationRepository>(
      (ref) => MediaOrganizationRepositoryImpl(
        ref.watch(localMediaOrganizationDataSourceProvider),
      ),
    );

final moveMediaToGroupProvider = Provider(
  (ref) => MoveMediaToGroup(ref.watch(mediaOrganizationRepositoryProvider)),
);

final moveMediaItemsProvider = Provider(
  (ref) => MoveMediaItems(ref.watch(mediaOrganizationRepositoryProvider)),
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

final validateMediaGroupProvider = Provider(
  (ref) => ValidateMediaGroup(ref.watch(readGalleryDirectoryProvider)),
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
