import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../gallery/domain/entities/gallery_item.dart';
import '../../domain/repositories/seek_preview_frame_repository.dart';

final class PlatformSeekPreviewFrameRepository
    implements SeekPreviewFrameRepository {
  PlatformSeekPreviewFrameRepository({
    MethodChannel channel = const MethodChannel(channelName),
    Future<Directory> Function()? getCacheDirectory,
  }) : _channel = channel,
       _getCacheDirectory = getCacheDirectory ?? getApplicationCacheDirectory;

  static const channelName = 'hello_gallery/platform_thumbnail';
  static const _maximumMemoryEntries = 32;
  static const _maximumDiskEntries = 512;
  static const _extractorVersion = 'native-seek-preview-v4';

  final MethodChannel _channel;
  final Future<Directory> Function() _getCacheDirectory;
  final _memoryCache = <String, SeekPreviewFrame>{};
  final _pending = <String, Future<SeekPreviewFrame?>>{};
  Future<Directory>? _cacheDirectory;
  int _writesSincePrune = 0;

  @override
  Future<SeekPreviewFrame?> getFrame(
    MediaItem item,
    Duration position, {
    int width = 240,
    bool precise = false,
  }) async {
    if (!item.isVideo) return null;
    final clampedPosition = position < Duration.zero ? Duration.zero : position;
    final normalizedPosition = _quantizePosition(clampedPosition, precise);
    final normalizedWidth = width.clamp(120, 480);
    final key = _frameKey(item, normalizedPosition, normalizedWidth, precise);
    final memoryBytes = _memoryCache.remove(key);
    if (memoryBytes != null) {
      _memoryCache[key] = memoryBytes;
      return memoryBytes;
    }

    final cacheFile = await _frameFile(item, key);
    if (await cacheFile.exists()) {
      try {
        final bytes = await cacheFile.readAsBytes();
        if (bytes.isNotEmpty) {
          final frame = SeekPreviewFrame(
            bytes: bytes,
            requestedPosition: normalizedPosition,
            actualPosition: normalizedPosition,
            precise: precise,
          );
          _remember(key, frame);
          return frame;
        }
      } on Object {
        // Regenerate an unreadable cache entry.
      }
    }

    final pending = _pending[key];
    if (pending != null) return pending;
    final request = _extract(
      item: item,
      position: normalizedPosition,
      width: normalizedWidth,
      precise: precise,
      cacheKey: key,
      cacheFile: cacheFile,
    );
    _pending[key] = request;
    try {
      return await request;
    } finally {
      _pending.remove(key);
    }
  }

  Future<SeekPreviewFrame?> _extract({
    required MediaItem item,
    required Duration position,
    required int width,
    required bool precise,
    required String cacheKey,
    required File cacheFile,
  }) async {
    try {
      final response = await _channel.invokeMethod<Object?>('getFrame', {
        'path': item.path,
        'timestampMs': position.inMilliseconds,
        'size': width,
        'precise': precise,
      });
      final Uint8List? bytes;
      var actualPosition = position;
      if (response case final Uint8List legacyBytes) {
        bytes = legacyBytes;
      } else if (response case final Map<Object?, Object?> values) {
        bytes = values['bytes'] as Uint8List?;
        final actualTimestampMs = values['actualTimestampMs'];
        if (actualTimestampMs is int) {
          actualPosition = Duration(milliseconds: actualTimestampMs);
        }
      } else {
        bytes = null;
      }
      if (bytes == null || bytes.isEmpty) return null;
      final frame = SeekPreviewFrame(
        bytes: bytes,
        requestedPosition: position,
        actualPosition: actualPosition,
        precise: precise,
      );
      _remember(cacheKey, frame);
      unawaited(_persist(cacheFile, bytes));
      return frame;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _persist(File output, Uint8List bytes) async {
    try {
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes, flush: false);
      _writesSincePrune++;
      if (_writesSincePrune >= 32) {
        _writesSincePrune = 0;
        await _pruneDiskCache(output.parent.parent);
      }
    } on Object {
      // Disk cache failures should not affect the in-memory preview.
    }
  }

  Future<File> _frameFile(MediaItem item, String frameKey) async {
    final cacheRoot = await (_cacheDirectory ??= _getCacheDirectory());
    return File(
      path.join(
        cacheRoot.path,
        'seek_preview_frames',
        _mediaKey(item),
        '$frameKey.jpg',
      ),
    );
  }

  String _frameKey(
    MediaItem item,
    Duration position,
    int width,
    bool precise,
  ) => _hash(
    '$_extractorVersion\u0000${_mediaKey(item)}\u0000${position.inMilliseconds}\u0000$width\u0000$precise',
  );

  String _mediaKey(MediaItem item) => _hash(
    '${item.path}\u0000${item.sizeBytes}\u0000${item.modifiedAt.microsecondsSinceEpoch}',
  );

  String _hash(String source) {
    var hash = 0xcbf29ce484222325;
    for (final byte in source.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  Duration _quantizePosition(Duration position, bool precise) {
    if (!precise) return position;
    const quantumMs = 250;
    final quantizedMs = (position.inMilliseconds ~/ quantumMs) * quantumMs;
    return Duration(milliseconds: quantizedMs);
  }

  void _remember(String key, SeekPreviewFrame frame) {
    _memoryCache.remove(key);
    _memoryCache[key] = frame;
    while (_memoryCache.length > _maximumMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  Future<void> _pruneDiskCache(Directory root) async {
    try {
      final files = await root
          .list(recursive: true)
          .where((entity) => entity is File && entity.path.endsWith('.jpg'))
          .cast<File>()
          .toList();
      if (files.length <= _maximumDiskEntries) return;
      final entries = <({File file, DateTime modified})>[];
      for (final file in files) {
        entries.add((file: file, modified: await file.lastModified()));
      }
      entries.sort((a, b) => a.modified.compareTo(b.modified));
      for (final entry in entries.take(files.length - _maximumDiskEntries)) {
        await entry.file.delete();
      }
    } on Object {
      // Cache cleanup is intentionally best effort.
    }
  }
}
