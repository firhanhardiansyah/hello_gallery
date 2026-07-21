import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../application/providers/gallery_dependencies.dart';
import '../../../domain/entities/gallery_item.dart';
import '../../../domain/entities/media_move.dart';

Future<MediaMoveResult?> showMediaMoveProgressDialog({
  required BuildContext context,
  required List<MediaItem> items,
  required String destinationPath,
}) {
  return showDialog<MediaMoveResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _MediaMoveProgressDialog(
      items: items,
      destinationPath: destinationPath,
    ),
  );
}

class _MediaMoveProgressDialog extends ConsumerStatefulWidget {
  const _MediaMoveProgressDialog({
    required this.items,
    required this.destinationPath,
  });

  final List<MediaItem> items;
  final String destinationPath;

  @override
  ConsumerState<_MediaMoveProgressDialog> createState() =>
      _MediaMoveProgressDialogState();
}

class _MediaMoveProgressDialogState
    extends ConsumerState<_MediaMoveProgressDialog> {
  late MediaMoveProgress _progress;

  @override
  void initState() {
    super.initState();
    _progress = MediaMoveProgress(
      completed: 0,
      total: widget.items.length,
      currentFileName: widget.items.first.name,
      moved: 0,
      skipped: 0,
      failed: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_move()));
  }

  Future<void> _move() async {
    final result = await ref.read(moveMediaItemsProvider)(
      items: widget.items,
      destinationPath: widget.destinationPath,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
      title: Text('Moving ${widget.items.length} media'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _progress.currentFileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            LinearProgressIndicator(value: _progress.fraction),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_progress.completed} of ${_progress.total} media'),
                Text('${_progress.percentage}%'),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
