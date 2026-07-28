import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../../domain/value_objects/media_playback_config.dart';

final class MediaKitVideoColorConfigurator {
  const MediaKitVideoColorConfigurator(this.config);

  final MediaPlaybackConfig config;

  static const sdrToneMappingProperties = <String, String>{
    'target-trc': 'gamma2.2',
    'target-prim': 'bt.709',
    'target-peak': '203',
    'tone-mapping': 'hable',
    'tone-mapping-param': 'default',
    'hdr-compute-peak': 'yes',
    'inverse-tone-mapping': 'no',
    'tone-mapping-max-boost': '1.0',
    'video-output-levels': 'full',
    'dither-depth': '8',
  };
  static const automaticHdrProperties = <String, String>{
    'target-trc': 'auto',
    'target-prim': 'auto',
    'target-peak': 'auto',
    'tone-mapping': 'auto',
    'tone-mapping-param': 'default',
    'hdr-compute-peak': 'auto',
    'inverse-tone-mapping': 'no',
    'tone-mapping-max-boost': '1.0',
    'video-output-levels': 'auto',
    'dither-depth': 'auto',
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
      }
    }
  }
}
