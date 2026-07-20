import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/settings_dependencies.dart';
import '../states/settings_ui_state.dart';

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsUiState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsUiState> {
  @override
  SettingsUiState build() {
    Future.microtask(_load);
    return const SettingsUiState();
  }

  Future<void> _load() async {
    final rootPath = await ref.read(loadGalleryRootProvider)();
    state = SettingsUiState(rootPath: rootPath, isLoading: false);
  }

  Future<bool> chooseRootFolder() async {
    try {
      final selectedPath = await ref.read(chooseGalleryRootProvider)(
        initialDirectory: state.rootPath,
      );
      if (selectedPath == null) return false;
      state = SettingsUiState(rootPath: selectedPath, isLoading: false);
      return true;
    } on Object {
      return false;
    }
  }
}
