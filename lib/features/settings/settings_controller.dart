import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

import 'settings_repository.dart';
import 'settings_state.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  final _secureBookmarks = SecureBookmarks();
  FileSystemEntity? _scopedRoot;

  @override
  SettingsState build() {
    ref.onDispose(() => unawaited(_releaseScopedRoot()));
    Future.microtask(_load);
    return const SettingsState();
  }

  Future<void> _load() async {
    final repository = ref.read(settingsRepositoryProvider);
    var rootPath = await repository.readRootPath();
    if (Platform.isMacOS && rootPath != null) {
      final bookmark = await repository.readRootBookmark();
      if (bookmark == null) {
        // Existing path-only settings cannot restore sandbox permission.
        rootPath = null;
      } else {
        try {
          final entity = await _secureBookmarks.resolveBookmark(
            bookmark,
            isDirectory: true,
          );
          final granted = await _secureBookmarks
              .startAccessingSecurityScopedResource(entity);
          if (granted && await entity.exists()) {
            _scopedRoot = entity;
            rootPath = entity.path;
          } else {
            rootPath = null;
          }
        } on Object {
          rootPath = null;
        }
      }
    } else if (rootPath != null && !await Directory(rootPath).exists()) {
      rootPath = null;
    }
    state = SettingsState(rootPath: rootPath, isLoading: false);
  }

  Future<bool> chooseRootFolder() async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose gallery root folder',
      initialDirectory: state.rootPath,
    );
    if (selectedPath == null) return false;
    try {
      String? bookmark;
      if (Platform.isMacOS) {
        final entity = Directory(selectedPath);
        bookmark = await _secureBookmarks.bookmark(entity);
        await _releaseScopedRoot();
      }
      await ref
          .read(settingsRepositoryProvider)
          .saveRootPath(selectedPath, bookmark: bookmark);
      state = SettingsState(rootPath: selectedPath, isLoading: false);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _releaseScopedRoot() async {
    final entity = _scopedRoot;
    _scopedRoot = null;
    if (entity != null && Platform.isMacOS) {
      await _secureBookmarks.stopAccessingSecurityScopedResource(entity);
    }
  }
}
