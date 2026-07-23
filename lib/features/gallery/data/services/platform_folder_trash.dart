import 'dart:io';

import 'package:flutter/services.dart';

class PlatformFolderTrash {
  const PlatformFolderTrash();

  static const _channel = MethodChannel('hello_gallery/folder_management');

  Future<void> moveToTrash(String entityPath) async {
    if (!Platform.isMacOS && !Platform.isWindows) {
      throw UnsupportedError('Trash is only supported on macOS and Windows.');
    }
    await _channel.invokeMethod<void>('moveToTrash', {'path': entityPath});
  }
}
