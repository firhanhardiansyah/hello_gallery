import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/rules/folder_name_rules.dart';

typedef FolderNameSubmit = Future<void> Function(String folderName);

Future<bool> showFolderNameDialog({
  required BuildContext context,
  required String title,
  required String locationPath,
  required String submitLabel,
  required FolderNameSubmit onSubmit,
  String initialName = '',
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _FolderNameDialog(
          title: title,
          locationPath: locationPath,
          submitLabel: submitLabel,
          initialName: initialName,
          onSubmit: onSubmit,
        ),
      ) ??
      false;
}

Future<bool> showMoveFolderToTrashDialog({
  required BuildContext context,
  required String folderName,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Move “$folderName” to Trash?'),
          content: const Text(
            'The folder and all of its contents will be removed from the '
            'gallery. You can restore it from Trash or Recycle Bin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                size: 18,
              ),
              label: const Text('Move to Trash'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<T> runFolderOperationWithProgress<T>({
  required BuildContext context,
  required String message,
  required Future<T> Function() operation,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
  try {
    return await operation();
  } finally {
    if (navigator.mounted && navigator.canPop()) navigator.pop();
  }
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({
    required this.title,
    required this.locationPath,
    required this.submitLabel,
    required this.initialName,
    required this.onSubmit,
  });

  final String title;
  final String locationPath;
  final String submitLabel;
  final String initialName;
  final FolderNameSubmit onSubmit;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  bool _submitting = false;
  String? _operationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _operationError = null;
    });
    try {
      await widget.onSubmit(_controller.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _operationError = folderOperationErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.locationPath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const ValueKey('folder-name-field'),
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_submitting,
                textInputAction: TextInputAction.done,
                validator: FolderNameRules.validate,
                onFieldSubmitted: (_) => unawaited(_submit()),
                decoration: InputDecoration(
                  labelText: 'Folder name',
                  errorText: _operationError,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_submitting) ...[
                const SizedBox(height: AppSpacing.lg),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    ),
  );
}

String folderOperationErrorMessage(Object error) {
  if (error case PlatformException(:final message?)) return message;
  if (error case ArgumentError(:final message?)) return '$message';
  return error.toString().replaceFirst('FileSystemException: ', '');
}
