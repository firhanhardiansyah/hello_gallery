import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/application/providers/gallery_dependencies.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/gallery_repository.dart';
import 'package:hello_gallery/features/gallery/domain/repositories/media_organization_repository.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/media_grouping/group_media_dialog.dart';

void main() {
  testWidgets('validates filenames and shows determinate move progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final organizationRepository = _BlockingOrganizationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryRepositoryProvider.overrideWithValue(
            const _FakeGalleryRepository(),
          ),
          mediaOrganizationRepositoryProvider.overrideWithValue(
            organizationRepository,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GroupMediaDialog(
              rootPath: '/gallery',
              currentDirectoryPath: '/gallery/One Piece',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('group-media-file-names')),
      'luffy.jpg',
    );
    await tester.enterText(
      find.byKey(const ValueKey('group-media-folder-name')),
      'Characters',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('1 media found'), findsOneWidget);
    expect(find.text('Move 1 media'), findsOneWidget);

    await tester.tap(find.text('Move 1 media'));
    await tester.pump();

    expect(find.text('Moving media'), findsOneWidget);
    expect(find.text('0 of 1 media'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    organizationRepository.releaseMove();
    await tester.pumpAndSettle();

    expect(find.text('Grouping complete'), findsOneWidget);
    expect(find.text('Moved'), findsOneWidget);
  });
}

class _FakeGalleryRepository implements GalleryRepository {
  const _FakeGalleryRepository();

  @override
  Future<List<GalleryItem>> readDirectory(String directoryPath) async => [
    MediaItem(
      path: '$directoryPath/luffy.jpg',
      name: 'luffy.jpg',
      modifiedAt: DateTime(2026),
      mediaType: GalleryItemType.image,
      sizeBytes: 10,
    ),
  ];

  @override
  Future<List<MediaItem>> readMediaRecursively(String rootPath) async => [];
}

class _BlockingOrganizationRepository implements MediaOrganizationRepository {
  final _moveCompleter = Completer<void>();

  void releaseMove() => _moveCompleter.complete();

  @override
  Future<void> createDirectory(String directoryPath) async {}

  @override
  Future<bool> fileExists(String filePath) async {
    return !filePath.endsWith('/Characters/luffy.jpg');
  }

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) {
    return _moveCompleter.future;
  }
}
