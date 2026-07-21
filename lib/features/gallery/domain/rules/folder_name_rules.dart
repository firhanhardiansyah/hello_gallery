import 'package:path/path.dart' as path;

abstract final class FolderNameRules {
  static String? validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter a folder name.';
    if (name == '.' ||
        name == '..' ||
        path.isAbsolute(name) ||
        path.basename(name) != name ||
        name.contains('/') ||
        name.contains(r'\')) {
      return 'Folder name cannot contain path separators.';
    }
    return null;
  }
}
