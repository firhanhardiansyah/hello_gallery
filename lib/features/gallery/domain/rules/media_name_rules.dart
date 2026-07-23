import 'package:path/path.dart' as path;

abstract final class MediaNameRules {
  static String? validateBaseName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter a file name.';
    if (name == '.' ||
        name == '..' ||
        path.isAbsolute(name) ||
        path.basename(name) != name ||
        name.contains('/') ||
        name.contains(r'\')) {
      return 'File name cannot contain path separators.';
    }
    return null;
  }
}
