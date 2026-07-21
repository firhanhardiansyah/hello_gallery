import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/services/gallery_directory_cache.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/read_gallery_directory.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/validate_media_group.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/entities/media_grouping.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/gallery_repository.dart';

void main() {
  const sourcePath = '/gallery/One Piece';
  final repository = _FakeGalleryRepository([
    MediaItem(
      path: '$sourcePath/luffy.jpg',
      name: 'luffy.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
      sizeBytes: 10,
    ),
    MediaItem(
      path: '$sourcePath/episode.mp4',
      name: 'episode.mp4',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.video,
      sizeBytes: 20,
    ),
  ]);
  late ReadGalleryDirectory readGalleryDirectory;

  setUp(() {
    readGalleryDirectory = ReadGalleryDirectory(
      repository,
      GalleryDirectoryCache(),
    );
  });

  test('validates direct media filenames and removes duplicates', () async {
    final result = await ValidateMediaGroup(readGalleryDirectory)(
      const GroupMediaRequest(
        rootPath: '/gallery',
        sourceDirectoryPath: sourcePath,
        destinationParentPath: sourcePath,
        groupName: 'Favorites',
        fileNames: [
          'luffy.jpg',
          'luffy.jpg',
          'episode.mp4',
          'missing.jpg',
          'nested/zoro.jpg',
        ],
      ),
    );

    expect(result.destinationPath, '$sourcePath/Favorites');
    expect(result.readyFileNames, ['luffy.jpg', 'episode.mp4']);
    expect(result.missingFileNames, ['missing.jpg']);
    expect(result.invalidFileNames, ['nested/zoro.jpg']);
    expect(result.canMove, isTrue);
  });

  test('rejects a destination outside the gallery root', () async {
    final result = await ValidateMediaGroup(readGalleryDirectory)(
      const GroupMediaRequest(
        rootPath: '/gallery',
        sourceDirectoryPath: sourcePath,
        destinationParentPath: '/other',
        groupName: 'Favorites',
        fileNames: ['luffy.jpg'],
      ),
    );

    expect(result.canMove, isFalse);
    expect(result.errorMessage, contains('inside the gallery root'));
  });
}

class _FakeGalleryRepository implements GalleryRepository {
  const _FakeGalleryRepository(this.items);

  final List<GalleryItem> items;

  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async => items;

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async => [];
}
