import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/rules/media_name_rules.dart';
import '../folder_management/folder_management_dialogs.dart';

typedef MediaNameSubmit = Future<void> Function(String baseName);

Future<bool> showMediaNameDialog({
  required BuildContext context,
  required String locationPath,
  required String initialBaseName,
  required String extension,
  required MediaNameSubmit onSubmit,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _MediaNameDialog(
          locationPath: locationPath,
          initialBaseName: initialBaseName,
          extension: extension,
          onSubmit: onSubmit,
        ),
      ) ??
      false;
}

Future<bool> showMoveMediaToTrashDialog({
  required BuildContext context,
  required List<String> mediaNames,
}) async {
  final count = mediaNames.length;
  final description = count == 1
      ? '“${mediaNames.single}” will be removed from the gallery.'
      : '$count selected media files will be removed from the gallery.';
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            count == 1 ? 'Move file to Trash?' : 'Move files to Trash?',
          ),
          content: Text(
            '$description You can restore ${count == 1 ? 'it' : 'them'} from '
            'Trash or Recycle Bin.',
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

class _MediaNameDialog extends StatefulWidget {
  const _MediaNameDialog({
    required this.locationPath,
    required this.initialBaseName,
    required this.extension,
    required this.onSubmit,
  });

  final String locationPath;
  final String initialBaseName;
  final String extension;
  final MediaNameSubmit onSubmit;

  @override
  State<_MediaNameDialog> createState() => _MediaNameDialogState();
}

class _MediaNameDialogState extends State<_MediaNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  bool _submitting = false;
  String? _operationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBaseName);
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
      title: const Text('Rename file'),
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
                key: const ValueKey('media-name-field'),
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_submitting,
                textInputAction: TextInputAction.done,
                validator: MediaNameRules.validateBaseName,
                onFieldSubmitted: (_) => unawaited(_submit()),
                decoration: InputDecoration(
                  labelText: 'File name',
                  suffixText: widget.extension,
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
          child: const Text('Rename'),
        ),
      ],
    ),
  );
}
