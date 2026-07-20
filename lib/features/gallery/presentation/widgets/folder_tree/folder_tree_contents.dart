import '../../../domain/entities/gallery_item.dart';

class FolderTreeContents {
  const FolderTreeContents({this.folders = const [], this.media = const []});

  final List<GalleryFolder> folders;
  final List<MediaItem> media;
}
