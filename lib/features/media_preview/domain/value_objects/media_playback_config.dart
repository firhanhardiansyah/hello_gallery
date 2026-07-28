class MediaPlaybackConfig {
  const MediaPlaybackConfig({this.hdrEnabled = false});

  final bool hdrEnabled;

  MediaPlaybackConfig copyWith({bool? hdrEnabled}) =>
      MediaPlaybackConfig(hdrEnabled: hdrEnabled ?? this.hdrEnabled);
}
