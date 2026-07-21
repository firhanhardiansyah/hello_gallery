import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/move_media_items.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/entities/media_move.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/media_organization_repository.dart';

void main() {
  test(
    'moves media in a batch and skips conflicts and same-folder drops',
    () async {
      final repository = _FakeMediaOrganizationRepository({
        '/gallery/source/one.jpg',
        '/gallery/source/two.mp4',
        '/gallery/target/two.mp4',
      });
      MediaMoveProgress? progress;
      final items = [
        _media('/gallery/source/one.jpg'),
        _media('/gallery/source/two.mp4', video: true),
        _media('/gallery/target/already-there.jpg'),
      ];

      final result = await MoveMediaItems(repository)(
        items: items,
        destinationPath: '/gallery/target',
        onProgress: (value) => progress = value,
      );

      expect(result.moved, 1);
      expect(result.skipped, 2);
      expect(result.failed, 0);
      expect(repository.files, contains('/gallery/target/one.jpg'));
      expect(progress?.completed, 3);
      expect(progress?.percentage, 100);
    },
  );
}

MediaItem _media(String path, {bool video = false}) => MediaItem(
  path: path,
  name: path.split('/').last,
  modifiedAt: DateTime(2026),
  mediaType: video ? GalleryItemType.video : GalleryItemType.image,
);

class _FakeMediaOrganizationRepository implements MediaOrganizationRepository {
  _FakeMediaOrganizationRepository(Set<String> files) : files = {...files};

  final Set<String> files;

  @override
  Future<void> createDirectory(String directoryPath) async {}

  @override
  Future<bool> fileExists(String filePath) async => files.contains(filePath);

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    files
      ..remove(sourcePath)
      ..add(destinationPath);
  }
}
