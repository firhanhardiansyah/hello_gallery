import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../../data/services/platform_root_folder_access.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/root_folder_access.dart';
import '../use_cases/choose_gallery_root.dart';
import '../use_cases/load_gallery_root.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(),
);

final rootFolderAccessProvider = Provider<RootFolderAccess>((ref) {
  final access = PlatformRootFolderAccess();
  ref.onDispose(access.release);
  return access;
});

final loadGalleryRootProvider = Provider(
  (ref) => LoadGalleryRoot(
    ref.watch(settingsRepositoryProvider),
    ref.watch(rootFolderAccessProvider),
  ),
);

final chooseGalleryRootProvider = Provider(
  (ref) => ChooseGalleryRoot(
    ref.watch(settingsRepositoryProvider),
    ref.watch(rootFolderAccessProvider),
  ),
);
