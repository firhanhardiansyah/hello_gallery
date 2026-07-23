import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum MediaContextAction { rename, moveToTrash }

Future<void> showMediaContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required VoidCallback onMoveToTrash,
  VoidCallback? onRename,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final action = await showMenu<MediaContextAction>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    ),
    items: [
      if (onRename != null)
        const PopupMenuItem(
          value: MediaContextAction.rename,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: HugeIcon(icon: HugeIcons.strokeRoundedFileEdit, size: 20),
            title: Text('Rename'),
          ),
        ),
      PopupMenuItem(
        value: MediaContextAction.moveToTrash,
        child: Builder(
          builder: (context) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Move to Trash',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    ],
  );
  switch (action) {
    case MediaContextAction.rename:
      onRename?.call();
    case MediaContextAction.moveToTrash:
      onMoveToTrash();
    case null:
      return;
  }
}
