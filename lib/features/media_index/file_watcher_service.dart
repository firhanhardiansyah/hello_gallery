/// Stage-two boundary for debounced, incremental filesystem events.
abstract interface class FileWatcherService {
  Stream<String> watch(String rootPath);
  Future<void> dispose();
}
