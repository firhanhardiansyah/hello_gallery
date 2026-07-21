class MediaMoveProgress {
  const MediaMoveProgress({
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

class MediaMoveResult {
  const MediaMoveResult({
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
