import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/media_preview/application/providers/media_preview_dependencies.dart';
import 'package:hello_gallery/features/media_preview/data/services/media_kit_video_color_configurator.dart';
import 'package:hello_gallery/features/media_preview/domain/value_objects/media_playback_config.dart';

void main() {
  test('disables HDR playback by default with SDR tone mapping', () {
    const config = MediaPlaybackConfig();
    final configurator = MediaKitVideoColorConfigurator(config);

    expect(config.hdrEnabled, isFalse);
    expect(
      configurator.properties,
      MediaKitVideoColorConfigurator.sdrToneMappingProperties,
    );
  });

  test('restores automatic native color output when HDR is enabled', () {
    const config = MediaPlaybackConfig(hdrEnabled: true);
    final configurator = MediaKitVideoColorConfigurator(config);

    expect(
      configurator.properties,
      MediaKitVideoColorConfigurator.automaticHdrProperties,
    );
  });

  test('toggles HDR playback at runtime', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(mediaPlaybackConfigProvider).hdrEnabled, isFalse);
    container.read(mediaPlaybackConfigProvider.notifier).toggleHdr();
    expect(container.read(mediaPlaybackConfigProvider).hdrEnabled, isTrue);
  });
}
