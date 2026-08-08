import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/value_objects/media_dimensions.dart';

final class PlatformMediaDimensionsDataSource {
  const PlatformMediaDimensionsDataSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'hello_gallery/platform_thumbnail';

  final MethodChannel _channel;

  Future<MediaDimensions?> readVideoDimensions(String path) async {
    if (!Platform.isMacOS && !Platform.isWindows) return null;
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'getDimensions',
        {'path': path},
      );
      final width = result?['width'];
      final height = result?['height'];
      if (width is! num || height is! num || width <= 0 || height <= 0) {
        return null;
      }
      return MediaDimensions(width: width.round(), height: height.round());
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
