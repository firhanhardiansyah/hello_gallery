import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/find_folder_preview_media.dart';
import 'package:hello_gallery/features/gallery/data/data_sources/local_gallery_data_source.dart';
import 'package:hello_gallery/features/gallery/data/repositories/gallery_repository_impl.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/gallery_repository.dart';

void main() {
  test('finds direct media before media in the nearest subfolders', () async {
    final root = await Directory.systemTemp.createTemp('folder_preview_bfs_');
    addTearDown(() => root.delete(recursive: true));
    final album = await Directory('${root.path}/album').create();
    final nested = await Directory('${album.path}/a-nested').create();
    final deeper = await Directory('${nested.path}/deeper').create();
    await File('${album.path}/z-cover.jpg').writeAsBytes(const [1]);
    await File('${nested.path}/a-clip.mp4').writeAsBytes(const [1]);
    await File('${deeper.path}/deep.jpg').writeAsBytes(const [1]);

    final finder = FindFolderPreviewMedia(
      GalleryRepositoryImpl(const LocalGalleryDataSource()),
    );
    final previews = await finder(album.path);

    expect(previews.map((item) => item.name), [
      'z-cover.jpg',
      'a-clip.mp4',
      'deep.jpg',
    ]);
  });

  test('limits the recursive preview result to four media', () async {
    final root = await Directory.systemTemp.createTemp('folder_preview_limit_');
    addTearDown(() => root.delete(recursive: true));
    final album = await Directory('${root.path}/album').create();
    final nested = await Directory('${album.path}/nested').create();
    for (var index = 0; index < 6; index++) {
      await File('${nested.path}/image-$index.jpg').writeAsBytes(const [1]);
    }

    final finder = FindFolderPreviewMedia(
      GalleryRepositoryImpl(const LocalGalleryDataSource()),
    );
    final previews = await finder(album.path);

    expect(previews, hasLength(4));
    expect(previews.map((item) => item.name), [
      'image-0.jpg',
      'image-1.jpg',
      'image-2.jpg',
      'image-3.jpg',
    ]);
  });

  test('continues past the soft folder limit until media is found', () async {
    final finder = FindFolderPreviewMedia(
      _DeepPreviewRepository(),
      maximumVisitedFolders: 2,
    );

    final previews = await finder('/folder-0');

    expect(previews.single.name, 'deep-preview.jpg');
  });
}

final class _DeepPreviewRepository implements GalleryRepository {
  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async {
    final index = int.parse(directoryPath.split('-').last);
    if (index == 3) {
      return [
        MediaItem(
          path: '$directoryPath/deep-preview.jpg',
          name: 'deep-preview.jpg',
          modifiedAt: DateTime(2026),
          mediaType: GalleryItemType.image,
        ),
      ];
    }
    return [
      GalleryFolder(
        path: '/folder-${index + 1}',
        name: 'folder-${index + 1}',
        modifiedAt: DateTime(2026),
      ),
    ];
  }

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async =>
      const [];
}
