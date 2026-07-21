import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum FolderContextAction { rename, moveToTrash }

Future<void> showFolderContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required VoidCallback onRename,
  required VoidCallback onMoveToTrash,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final action = await showMenu<FolderContextAction>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    ),
    items: [
      const PopupMenuItem(
        value: FolderContextAction.rename,
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: HugeIcon(icon: HugeIcons.strokeRoundedFolderEdit, size: 20),
          title: Text('Rename'),
        ),
      ),
      PopupMenuItem(
        value: FolderContextAction.moveToTrash,
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
    case FolderContextAction.rename:
      onRename();
    case FolderContextAction.moveToTrash:
      onMoveToTrash();
    case null:
      return;
  }
}
