import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/thumbnail_repository.dart';

final class ThumbnailRepositoryImpl implements ThumbnailRepository {
  // Configurable threshold for black frame detection (average luminance). Default matches previous hard‑coded value.
  final double blackLuminanceThreshold;
  // Maximum number of fallback attempts after the initial seek.
  final int maxFallbackAttempts;

  // Constructor allows optional customization; defaults preserve existing behaviour.
  ThumbnailRepositoryImpl({
    this.blackLuminanceThreshold = 18.0,
    this.maxFallbackAttempts = 2,
  });
  static const _platformThumbnailChannel = MethodChannel(
    'hello_gallery/platform_thumbnail',
  );
  Future<Directory>? _cacheDirectory;

  @override
  Future<String?> findCachedThumbnail(MediaItem item) async {
    final thumbnail = await _thumbnailFile(_cacheKey(item));
    return await thumbnail.exists() ? thumbnail.path : null;
  }

  @override
  Future<String?> getThumbnail(MediaItem item) async {
    if (!item.isVideo) return null;
    final key = _cacheKey(item);
    final thumbnail = await _thumbnailFile(key);
    final cacheDirectory = thumbnail.parent;
    if (await thumbnail.exists()) return thumbnail.path;

    if (Platform.isWindows || Platform.isMacOS) {
      try {
        final bytes = await _platformThumbnailChannel.invokeMethod<Uint8List>(
          'getThumbnail',
          {'path': item.path, 'size': 256},
        );
        if (bytes != null && bytes.isNotEmpty) {
          final isBlack = await _isBlackImage(bytes, blackLuminanceThreshold);
          if (!isBlack) {
            await cacheDirectory.create(recursive: true);
            await thumbnail.writeAsBytes(bytes, flush: false);
            return thumbnail.path;
          }
          debugPrint(
            'Native thumbnail for "${item.path}" was a black frame. Retrying with media_kit...',
          );
        }
      } on PlatformException catch (error) {
        debugPrint('Native platform thumbnail failed: $error');
      }
    }

    final player = Player(
      configuration: const PlayerConfiguration(muted: true),
    );
    try {
      final videoController = VideoController(
        player,
        configuration: const VideoControllerConfiguration(width: 320),
      );
      await videoController.platform.future.timeout(const Duration(seconds: 5));
      final videoReady = player.stream.width.firstWhere(
        (width) => width != null && width > 0,
      );
      await player.open(Media(item.path), play: false);
      await videoReady.timeout(const Duration(seconds: 5));
      final duration = player.state.duration;

      final tenPercent = Duration(
        microseconds: (duration.inMicroseconds * 0.1).round(),
      );
      var position = tenPercent < const Duration(milliseconds: 1500)
          ? const Duration(milliseconds: 1500)
          : tenPercent > const Duration(seconds: 5)
          ? const Duration(seconds: 5)
          : tenPercent;

      if (position >= duration && duration > Duration.zero) {
        position = Duration.zero;
      }

      await player.seek(position);
      var bytes = await player.screenshot(
        format: 'image/jpeg',
        includeLibassSubtitles: false,
      );

      if (bytes != null && bytes.isNotEmpty && await _isBlackImage(bytes, blackLuminanceThreshold)) {
          // Perform additional fallback attempts if the first frame is still black.
          Duration attemptOffset = const Duration(seconds: 3);
          for (int attempt = 0; attempt < maxFallbackAttempts; attempt++) {
            final nextPosition = position + attemptOffset * (attempt + 1);
            if (nextPosition >= duration) break;
            await player.seek(nextPosition);
            final attemptBytes = await player.screenshot(
              format: 'image/jpeg',
              includeLibassSubtitles: false,
            );
            if (attemptBytes != null && attemptBytes.isNotEmpty) {
              // Check if this frame is still black; if not, use it.
              final isBlack = await _isBlackImage(attemptBytes, blackLuminanceThreshold);
              if (!isBlack) {
                bytes = attemptBytes;
                break;
              }
            }
          }
        }

      if (bytes == null || bytes.isEmpty) return null;
      await cacheDirectory.create(recursive: true);
      await thumbnail.writeAsBytes(bytes, flush: false);
      return thumbnail.path;
    } finally {
      await player.dispose();
    }
  }

  @override
  Future<void> removeCachedThumbnail(MediaItem item) async {
    final thumbnail = await _thumbnailFile(_cacheKey(item));
    if (await thumbnail.exists()) await thumbnail.delete();
  }

  static Future<bool> _isBlackImage(Uint8List bytes, double threshold) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 32,
        targetHeight: 32,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();
      codec.dispose();
      if (byteData == null) return false;

      final buffer = byteData.buffer.asUint8List();
      int totalLuminance = 0;
      final pixelCount = buffer.length ~/ 4;
      for (var i = 0; i < buffer.length; i += 4) {
        final r = buffer[i];
        final g = buffer[i + 1];
        final b = buffer[i + 2];
        totalLuminance += (r * 299 + g * 587 + b * 114) ~/ 1000;
      }
      final averageLuminance = totalLuminance / pixelCount;
      return averageLuminance < threshold;
    } catch (_) {
      return false;
    }
  }

  Future<File> _thumbnailFile(String key) async {
    final cacheRoot = await (_cacheDirectory ??=
        getApplicationCacheDirectory());
    return File(path.join(cacheRoot.path, 'video_thumbnails', '$key.jpg'));
  }

  String _cacheKey(MediaItem item) {
    final generator = Platform.isWindows
        ? 'windows-shell-v2'
        : Platform.isMacOS
        ? 'macos-quick-look-v2'
        : 'media-kit-v2';
    final source =
        '$generator\u0000${item.path}\u0000${item.sizeBytes}\u0000${item.modifiedAt.microsecondsSinceEpoch}';
    var hash = 0xcbf29ce484222325;
    for (final byte in source.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
