String formatVideoDuration(Duration value, {required bool includeHours}) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (!includeHours) return '$minutes:$seconds';
  final hours = value.inHours.toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
