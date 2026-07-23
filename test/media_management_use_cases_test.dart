import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/move_media_to_trash.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/rename_media.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/media_management_repository.dart';

void main() {
  group('RenameMedia', () {
    test(
      'renames the base name while preserving the media extension',
      () async {
        final repository = _FakeMediaManagementRepository(
          existingPaths: {'/gallery/old.JPG'},
        );

        final destination = await RenameMedia(repository)(
          rootPath: '/gallery',
          mediaPath: '/gallery/old.JPG',
          newBaseName: 'holiday',
        );

        expect(destination, '/gallery/holiday.JPG');
        expect(repository.renames, [
          ('/gallery/old.JPG', '/gallery/holiday.JPG'),
        ]);
      },
    );

    test('rejects a destination that already exists', () async {
      final repository = _FakeMediaManagementRepository(
        existingPaths: {'/gallery/old.jpg', '/gallery/taken.jpg'},
      );

      await expectLater(
        RenameMedia(repository)(
          rootPath: '/gallery',
          mediaPath: '/gallery/old.jpg',
          newBaseName: 'taken',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('MoveMediaToTrash', () {
    test('continues moving remaining files after one failure', () async {
      final first = _media('/gallery/first.jpg');
      final second = _media('/gallery/second.mp4');
      final repository = _FakeMediaManagementRepository(
        existingPaths: {first.path, second.path},
        trashFailures: {first.path},
      );

      final result = await MoveMediaToTrash(repository)(
        rootPath: '/gallery',
        items: [first, second],
      );

      expect(result.moved, [second]);
      expect(result.failed.keys, [first]);
      expect(repository.trashRequests, [first.path, second.path]);
    });

    test('deduplicates repeated media paths', () async {
      final item = _media('/gallery/photo.jpg');
      final repository = _FakeMediaManagementRepository(
        existingPaths: {item.path},
      );

      final result = await MoveMediaToTrash(repository)(
        rootPath: '/gallery',
        items: [item, item],
      );

      expect(result.moved, [item]);
      expect(repository.trashRequests, [item.path]);
    });
  });
}

MediaItem _media(String path) => MediaItem(
  path: path,
  name: path.split('/').last,
  modifiedAt: DateTime(2026),
  mediaType: path.endsWith('.mp4')
      ? GalleryItemType.video
      : GalleryItemType.image,
);

final class _FakeMediaManagementRepository
    implements MediaManagementRepository {
  _FakeMediaManagementRepository({
    required Set<String> existingPaths,
    this.trashFailures = const {},
  }) : _existingPaths = {...existingPaths};

  final Set<String> _existingPaths;
  final Set<String> trashFailures;
  final List<(String, String)> renames = [];
  final List<String> trashRequests = [];

  @override
  Future<bool> fileExists(String filePath) async {
    return _existingPaths.contains(filePath);
  }

  @override
  Future<bool> entityExists(String entityPath) async {
    return _existingPaths.contains(entityPath);
  }

  @override
  Future<void> renameMedia(String oldPath, String newPath) async {
    renames.add((oldPath, newPath));
    _existingPaths
      ..remove(oldPath)
      ..add(newPath);
  }

  @override
  Future<void> moveMediaToTrash(String filePath) async {
    trashRequests.add(filePath);
    if (trashFailures.contains(filePath)) {
      throw FileSystemException('Trash failed', filePath);
    }
    _existingPaths.remove(filePath);
  }
}
