class GroupMediaRequest {
  const GroupMediaRequest({
    required this.rootPath,
    required this.sourceDirectoryPath,
    required this.destinationParentPath,
    required this.groupName,
    required this.fileNames,
  });

  final String rootPath;
  final String sourceDirectoryPath;
  final String destinationParentPath;
  final String groupName;
  final List<String> fileNames;
}

class GroupMediaValidation {
  const GroupMediaValidation({
    required this.destinationPath,
    required this.readyFileNames,
    required this.missingFileNames,
    required this.invalidFileNames,
    this.errorMessage,
  });

  final String destinationPath;
  final List<String> readyFileNames;
  final List<String> missingFileNames;
  final List<String> invalidFileNames;
  final String? errorMessage;

  int get readyCount => readyFileNames.length;
  bool get canMove => errorMessage == null && readyFileNames.isNotEmpty;
}

class GroupMediaProgress {
  const GroupMediaProgress({
    required this.completed,
    required this.total,
    required this.currentFileName,
    required this.moved,
    required this.skipped,
    required this.failed,
  });

  final int completed;
  final int total;
  final String currentFileName;
  final int moved;
  final int skipped;
  final int failed;

  double get fraction => total == 0 ? 0 : completed / total;
  int get percentage => (fraction * 100).round();
}

class GroupMediaResult {
  const GroupMediaResult({
    required this.destinationPath,
    required this.moved,
    required this.skipped,
    required this.failed,
  });

  final String destinationPath;
  final int moved;
  final int skipped;
  final int failed;
}
