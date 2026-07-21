import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/move_media_to_group.dart';
import 'package:hello_gallery/features/gallery/domain/entities/media_grouping.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/media_organization_repository.dart';

void main() {
  test('moves available files and skips destination conflicts', () async {
    final repository = _FakeMediaOrganizationRepository({
      '/gallery/source/one.jpg',
      '/gallery/source/two.jpg',
      '/gallery/group/two.jpg',
    });
    GroupMediaProgress? progress;

    final result = await MoveMediaToGroup(repository)(
      sourceDirectoryPath: '/gallery/source',
      destinationPath: '/gallery/group',
      fileNames: const ['one.jpg', 'two.jpg', 'missing.jpg'],
      onProgress: (value) => progress = value,
    );

    expect(repository.createdDirectories, ['/gallery/group']);
    expect(repository.files, contains('/gallery/group/one.jpg'));
    expect(repository.files, isNot(contains('/gallery/source/one.jpg')));
    expect(result.moved, 1);
    expect(result.skipped, 1);
    expect(result.failed, 1);
    expect(progress?.completed, 3);
    expect(progress?.percentage, 100);
  });
}

class _FakeMediaOrganizationRepository implements MediaOrganizationRepository {
  _FakeMediaOrganizationRepository(Set<String> files) : files = {...files};

  final Set<String> files;
  final List<String> createdDirectories = [];

  @override
  Future<void> createDirectory(String directoryPath) async {
    createdDirectories.add(directoryPath);
  }

  @override
  Future<bool> fileExists(String filePath) async => files.contains(filePath);

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    files
      ..remove(sourcePath)
      ..add(destinationPath);
  }
}
