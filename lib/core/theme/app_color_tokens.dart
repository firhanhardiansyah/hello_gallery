import 'package:flutter/material.dart';

@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.scaffoldBackground,
    required this.surface,
    required this.mediaBackground,
    required this.mediaPlaceholder,
    required this.loadingPlaceholder,
    required this.mediaOverlay,
    required this.mediaControlSurface,
    required this.onMedia,
    required this.onMediaMuted,
    required this.shadow,
  });

  static const indigoSeed = Color(0xFF6366F1);
  static const pinkSeed = Color(0xFFEC4899);
  static const emeraldSeed = Color(0xFF00897B);

  static const light = AppColorTokens(
    scaffoldBackground: Color(0xFFF8F9FC),
    surface: Color(0xFFFFFFFF),
    mediaBackground: Color(0xFF000000),
    mediaPlaceholder: Color(0xFFE7E7EC),
    loadingPlaceholder: Color(0xFFE2E3E9),
    mediaOverlay: Color(0x94000000),
    mediaControlSurface: Color(0xB8000000),
    onMedia: Color(0xFFFFFFFF),
    onMediaMuted: Color(0x8AFFFFFF),
    shadow: Color(0x33000000),
  );

  static const dark = AppColorTokens(
    scaffoldBackground: Color(0xFF101014),
    surface: Color(0xFF17171C),
    mediaBackground: Color(0xFF000000),
    mediaPlaceholder: Color(0xFF24242C),
    loadingPlaceholder: Color(0xFF222229),
    mediaOverlay: Color(0x94000000),
    mediaControlSurface: Color(0xB8000000),
    onMedia: Color(0xFFFFFFFF),
    onMediaMuted: Color(0x8AFFFFFF),
    shadow: Color(0x52000000),
  );

  final Color scaffoldBackground;
  final Color surface;
  final Color mediaBackground;
  final Color mediaPlaceholder;
  final Color loadingPlaceholder;
  final Color mediaOverlay;
  final Color mediaControlSurface;
  final Color onMedia;
  final Color onMediaMuted;
  final Color shadow;

  @override
  AppColorTokens copyWith({
    Color? scaffoldBackground,
    Color? surface,
    Color? mediaBackground,
    Color? mediaPlaceholder,
    Color? loadingPlaceholder,
    Color? mediaOverlay,
    Color? mediaControlSurface,
    Color? onMedia,
    Color? onMediaMuted,
    Color? shadow,
  }) {
    return AppColorTokens(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      surface: surface ?? this.surface,
      mediaBackground: mediaBackground ?? this.mediaBackground,
      mediaPlaceholder: mediaPlaceholder ?? this.mediaPlaceholder,
      loadingPlaceholder: loadingPlaceholder ?? this.loadingPlaceholder,
      mediaOverlay: mediaOverlay ?? this.mediaOverlay,
      mediaControlSurface: mediaControlSurface ?? this.mediaControlSurface,
      onMedia: onMedia ?? this.onMedia,
      onMediaMuted: onMediaMuted ?? this.onMediaMuted,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorTokens lerp(covariant AppColorTokens? other, double t) {
    if (other == null) return this;
    return AppColorTokens(
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      mediaBackground: Color.lerp(mediaBackground, other.mediaBackground, t)!,
      mediaPlaceholder: Color.lerp(
        mediaPlaceholder,
        other.mediaPlaceholder,
        t,
      )!,
      loadingPlaceholder: Color.lerp(
        loadingPlaceholder,
        other.loadingPlaceholder,
        t,
      )!,
      mediaOverlay: Color.lerp(mediaOverlay, other.mediaOverlay, t)!,
      mediaControlSurface: Color.lerp(
        mediaControlSurface,
        other.mediaControlSurface,
        t,
      )!,
      onMedia: Color.lerp(onMedia, other.onMedia, t)!,
      onMediaMuted: Color.lerp(onMediaMuted, other.onMediaMuted, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppColorTokensContext on BuildContext {
  AppColorTokens get appColors => Theme.of(this).extension<AppColorTokens>()!;
}
