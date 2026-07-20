import '../entities/gallery_root.dart';

abstract interface class RootFolderAccess {
  Future<String?> restore({required String? path, required String? bookmark});

  Future<GalleryRoot?> choose({String? initialDirectory});

  Future<void> release();
}
