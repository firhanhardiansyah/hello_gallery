import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/create_folder.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/move_folder_to_trash.dart';
import 'package:hello_gallery/features/gallery/application/use_cases/rename_folder.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/folder_management_repository.dart';

void main() {
  late _FakeFolderManagementRepository repository;

  setUp(() => repository = _FakeFolderManagementRepository());

  test('creates a folder inside the selected parent', () async {
    final result = await CreateFolder(repository)(
      rootPath: '/gallery',
      parentPath: '/gallery/One Piece',
      folderName: 'Characters',
    );

    expect(result, '/gallery/One Piece/Characters');
    expect(repository.createdPaths, [result]);
  });

  test('rejects duplicate and invalid folder names', () async {
    repository.existingPaths.add('/gallery/One Piece/Characters');
    final create = CreateFolder(repository);

    await expectLater(
      create(
        rootPath: '/gallery',
        parentPath: '/gallery/One Piece',
        folderName: 'Characters',
      ),
      throwsA(isA<FileSystemException>()),
    );
    await expectLater(
      create(
        rootPath: '/gallery',
        parentPath: '/gallery/One Piece',
        folderName: '../Characters',
      ),
      throwsArgumentError,
    );
  });

  test('renames a non-root folder', () async {
    final result = await RenameFolder(repository)(
      rootPath: '/gallery',
      folderPath: '/gallery/Anime',
      newName: 'Studio Ghibli',
    );

    expect(result, '/gallery/Studio Ghibli');
    expect(repository.renamedPaths, [
      ('/gallery/Anime', '/gallery/Studio Ghibli'),
    ]);
  });

  test('protects the gallery root from rename and trash', () async {
    await expectLater(
      RenameFolder(repository)(
        rootPath: '/gallery',
        folderPath: '/gallery',
        newName: 'Other',
      ),
      throwsArgumentError,
    );
    await expectLater(
      MoveFolderToTrash(repository)(
        rootPath: '/gallery',
        folderPath: '/gallery',
      ),
      throwsArgumentError,
    );
  });

  test('moves an existing folder to native trash', () async {
    repository.existingPaths.add('/gallery/Old');

    await MoveFolderToTrash(repository)(
      rootPath: '/gallery',
      folderPath: '/gallery/Old',
    );

    expect(repository.trashedPaths, ['/gallery/Old']);
  });
}

class _FakeFolderManagementRepository implements FolderManagementRepository {
  final existingPaths = <String>{};
  final createdPaths = <String>[];
  final renamedPaths = <(String, String)>[];
  final trashedPaths = <String>[];

  @override
  Future<void> createFolder(String folderPath) async {
    createdPaths.add(folderPath);
  }

  @override
  Future<bool> entityExists(String entityPath) async {
    return existingPaths.contains(entityPath);
  }

  @override
  Future<void> moveFolderToTrash(String folderPath) async {
    trashedPaths.add(folderPath);
  }

  @override
  Future<void> renameFolder(String oldPath, String newPath) async {
    renamedPaths.add((oldPath, newPath));
  }
}
