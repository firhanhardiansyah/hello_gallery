import '../entities/file_change.dart';

abstract interface class FileWatcherService {
  Stream<FileChange> watch(String rootPath);
}
