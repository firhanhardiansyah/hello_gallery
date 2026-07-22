import '../../domain/entities/gallery_view_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

final class SaveGalleryViewPreferences {
  const SaveGalleryViewPreferences(this._repository);

  final SettingsRepository _repository;

  Future<void> call(GalleryViewPreferences preferences) {
    return _repository.saveGalleryViewPreferences(preferences);
  }
}
