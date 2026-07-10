import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_repository.dart';
import 'settings_state.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future.microtask(_load);
    return const SettingsState();
  }

  Future<void> _load() async {
    final rootPath = await ref.read(settingsRepositoryProvider).readRootPath();
    state = SettingsState(rootPath: rootPath, isLoading: false);
  }

  Future<bool> chooseRootFolder() async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose gallery root folder',
      initialDirectory: state.rootPath,
    );
    if (selectedPath == null) return false;
    await ref.read(settingsRepositoryProvider).saveRootPath(selectedPath);
    state = SettingsState(rootPath: selectedPath, isLoading: false);
    return true;
  }
}
