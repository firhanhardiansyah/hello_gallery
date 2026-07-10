/// Stage-two boundary. Thumbnails should be generated off the UI isolate and
/// stored under the application cache directory.
abstract interface class ThumbnailService {
  Future<String?> thumbnailFor(String mediaPath);
}
