/// Stage-two boundary for recursive indexing and metadata persistence.
abstract interface class MediaIndexService {
  Future<void> indexRoot(String rootPath);
}
