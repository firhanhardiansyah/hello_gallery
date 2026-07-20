import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

import '../../domain/entities/gallery_root.dart';
import '../../domain/services/root_folder_access.dart';

final class PlatformRootFolderAccess implements RootFolderAccess {
  final _secureBookmarks = SecureBookmarks();
  FileSystemEntity? _scopedRoot;

  @override
  Future<String?> restore({
    required String? path,
    required String? bookmark,
  }) async {
    if (path == null) return null;
    if (!Platform.isMacOS) {
      return await Directory(path).exists() ? path : null;
    }
    if (bookmark == null) return null;
    try {
      final entity = await _secureBookmarks.resolveBookmark(
        bookmark,
        isDirectory: true,
      );
      final granted = await _secureBookmarks
          .startAccessingSecurityScopedResource(entity);
      if (!granted || !await entity.exists()) return null;
      _scopedRoot = entity;
      return entity.path;
    } on Object {
      return null;
    }
  }

  @override
  Future<GalleryRoot?> choose({String? initialDirectory}) async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose gallery root folder',
      initialDirectory: initialDirectory,
    );
    if (selectedPath == null) return null;
    if (!Platform.isMacOS) return GalleryRoot(path: selectedPath);
    final entity = Directory(selectedPath);
    final bookmark = await _secureBookmarks.bookmark(entity);
    await release();
    return GalleryRoot(path: selectedPath, bookmark: bookmark);
  }

  @override
  Future<void> release() async {
    final entity = _scopedRoot;
    _scopedRoot = null;
    if (entity != null && Platform.isMacOS) {
      await _secureBookmarks.stopAccessingSecurityScopedResource(entity);
    }
  }
}
