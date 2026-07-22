import '../../domain/entities/gallery_view_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

final class LoadGalleryViewPreferences {
  const LoadGalleryViewPreferences(this._repository);

  final SettingsRepository _repository;

  Future<GalleryViewPreferences> call() {
    return _repository.readGalleryViewPreferences();
  }
}
