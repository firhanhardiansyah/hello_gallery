import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../../domain/value_objects/media_playback_config.dart';

final class MediaKitVideoColorConfigurator {
  const MediaKitVideoColorConfigurator(this.config);

  final MediaPlaybackConfig config;

  static const sdrToneMappingProperties = <String, String>{
    'target-trc': 'srgb',
    'target-prim': 'bt.709',
    'tone-mapping': 'bt.2390',
  };
  static const automaticHdrProperties = <String, String>{
    'target-trc': 'auto',
    'target-prim': 'auto',
    'tone-mapping': 'auto',
  };

  Map<String, String> get properties =>
      config.hdrEnabled ? automaticHdrProperties : sdrToneMappingProperties;

  Future<void> configure(Player player) async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    for (final property in properties.entries) {
      if (platform.disposed) return;
      try {
        await platform.setProperty(property.key, property.value);
      } on Object catch (error) {
        debugPrint(
          'Could not configure video color property ${property.key}: $error',
        );
        return;
      }
    }
  }
}
