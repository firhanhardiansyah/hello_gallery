import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../application/providers/gallery_dependencies.dart';
import '../../../domain/entities/media_grouping.dart';
import '../../notifiers/gallery_notifier.dart';

Future<GroupMediaResult?> showGroupMediaDialog({
  required BuildContext context,
  required String rootPath,
  required String currentDirectoryPath,
}) {
  return showDialog<GroupMediaResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => GroupMediaDialog(
      rootPath: rootPath,
      currentDirectoryPath: currentDirectoryPath,
    ),
  );
}

class GroupMediaDialog extends ConsumerStatefulWidget {
  const GroupMediaDialog({
    required this.rootPath,
    required this.currentDirectoryPath,
    super.key,
  });

  final String rootPath;
  final String currentDirectoryPath;

  @override
  ConsumerState<GroupMediaDialog> createState() => _GroupMediaDialogState();
}

class _GroupMediaDialogState extends ConsumerState<GroupMediaDialog> {
  late final TextEditingController _fileNamesController;
  late final TextEditingController _destinationController;
  late final TextEditingController _groupNameController;
  final _fileNamesFocusNode = FocusNode();
  Timer? _validationDebounce;
  int _validationGeneration = 0;
  _GroupMediaStage _stage = _GroupMediaStage.editing;
  GroupMediaValidation? _validation;
  GroupMediaProgress? _progress;
  GroupMediaResult? _result;

  bool get _isBusy =>
      _stage == _GroupMediaStage.moving ||
      _stage == _GroupMediaStage.synchronizing;

  @override
  void initState() {
    super.initState();
    _fileNamesController = TextEditingController();
    _destinationController = TextEditingController(
      text: widget.currentDirectoryPath,
    );
    _groupNameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fileNamesFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    _fileNamesController.dispose();
    _destinationController.dispose();
    _groupNameController.dispose();
    _fileNamesFocusNode.dispose();
    super.dispose();
  }

  void _scheduleValidation() {
    if (_isBusy || _stage == _GroupMediaStage.complete) return;
    _validationDebounce?.cancel();
    setState(() {
      _stage = _GroupMediaStage.editing;
      _validation = null;
    });
    _validationDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_validate()),
    );
  }

  GroupMediaRequest _buildRequest() => GroupMediaRequest(
    rootPath: widget.rootPath,
    sourceDirectoryPath: widget.currentDirectoryPath,
    destinationParentPath: _destinationController.text.trim(),
    groupName: _groupNameController.text.trim(),
    fileNames: _fileNamesController.text.split(RegExp(r'\r?\n')),
  );

  Future<GroupMediaValidation?> _validate() async {
    final generation = ++_validationGeneration;
    if (mounted) setState(() => _stage = _GroupMediaStage.validating);
    try {
      final validation = await ref.read(validateMediaGroupProvider)(
        _buildRequest(),
      );
      if (!mounted || generation != _validationGeneration) return null;
      setState(() {
        _validation = validation;
        _stage = _GroupMediaStage.editing;
      });
      return validation;
    } on Object catch (error) {
      if (!mounted || generation != _validationGeneration) return null;
      final validation = GroupMediaValidation(
        destinationPath: '',
        readyFileNames: const [],
        missingFileNames: const [],
        invalidFileNames: const [],
        errorMessage: 'Could not validate media: $error',
      );
      setState(() {
        _validation = validation;
        _stage = _GroupMediaStage.editing;
      });
      return validation;
    }
  }

  Future<void> _move() async {
    _validationDebounce?.cancel();
    final validation = await _validate();
    if (!mounted || validation == null || !validation.canMove) return;

    setState(() {
      _stage = _GroupMediaStage.moving;
      _progress = GroupMediaProgress(
        completed: 0,
        total: validation.readyCount,
        currentFileName: validation.readyFileNames.first,
        moved: 0,
        skipped: 0,
        failed: 0,
      );
    });

    try {
      final result = await ref.read(moveMediaToGroupProvider)(
        sourceDirectoryPath: widget.currentDirectoryPath,
        destinationPath: validation.destinationPath,
        fileNames: validation.readyFileNames,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      setState(() => _stage = _GroupMediaStage.synchronizing);
      await ref.read(galleryNotifierProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _result = result;
        _stage = _GroupMediaStage.complete;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _validation = GroupMediaValidation(
          destinationPath: validation.destinationPath,
          readyFileNames: validation.readyFileNames,
          missingFileNames: validation.missingFileNames,
          invalidFileNames: validation.invalidFileNames,
          errorMessage: 'Could not move media: $error',
        );
        _stage = _GroupMediaStage.editing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              _submitWithShortcut,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true):
              _submitWithShortcut,
        },
        child: AlertDialog(
          scrollable: true,
          title: const Text('Group media'),
          content: SizedBox(
            width: 620,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: switch (_stage) {
                _GroupMediaStage.moving => _buildProgress(),
                _GroupMediaStage.synchronizing => _buildSynchronizing(),
                _GroupMediaStage.complete => _buildResult(),
                _ => _buildForm(),
              },
            ),
          ),
          actions: _buildActions(),
        ),
      ),
    );
  }

  void _submitWithShortcut() {
    if (_validation?.canMove ?? false) unawaited(_move());
  }

  Widget _buildForm() {
    final validation = _validation;
    final hasInput =
        _fileNamesController.text.trim().isNotEmpty ||
        _groupNameController.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Move media from the current folder into a group folder.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        _FolderPath(label: 'Source folder', path: widget.currentDirectoryPath),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const ValueKey('group-media-file-names'),
          controller: _fileNamesController,
          focusNode: _fileNamesFocusNode,
          enabled: !_isBusy,
          minLines: 7,
          maxLines: 10,
          onChanged: (_) => _scheduleValidation(),
          decoration: const InputDecoration(
            labelText: 'Media filenames',
            hintText: 'file1.jpg\nfile2.jpg\nfile3.mp4',
            helperText: 'Enter one filename per line.',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('group-media-destination'),
                controller: _destinationController,
                enabled: !_isBusy,
                onChanged: (_) => _scheduleValidation(),
                decoration: const InputDecoration(
                  labelText: 'Destination parent',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                key: const ValueKey('group-media-folder-name'),
                controller: _groupNameController,
                enabled: !_isBusy,
                onChanged: (_) => _scheduleValidation(),
                onSubmitted: (_) {
                  if (_validation?.canMove ?? false) unawaited(_move());
                },
                decoration: const InputDecoration(
                  labelText: 'Group folder name',
                  hintText: 'Characters',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_stage == _GroupMediaStage.validating)
          const LinearProgressIndicator()
        else if (validation != null && hasInput)
          _ValidationSummary(validation: validation),
      ],
    );
  }

  Widget _buildProgress() {
    final progress = _progress!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Moving media', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          progress.currentFileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.lg),
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${progress.completed} of ${progress.total} media'),
            Text('${progress.percentage}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildSynchronizing() => const Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Synchronizing gallery...'),
      SizedBox(height: AppSpacing.lg),
      LinearProgressIndicator(),
    ],
  );

  Widget _buildResult() {
    final result = _result!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Grouping complete',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const LinearProgressIndicator(value: 1),
        const SizedBox(height: AppSpacing.lg),
        _ResultRow(label: 'Moved', value: result.moved),
        _ResultRow(label: 'Skipped', value: result.skipped),
        _ResultRow(label: 'Failed', value: result.failed),
        const SizedBox(height: AppSpacing.md),
        _FolderPath(label: 'Destination', path: result.destinationPath),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_stage == _GroupMediaStage.complete) {
      return [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_result),
          child: const Text('Done'),
        ),
      ];
    }
    if (_isBusy) return const [];
    final count = _validation?.readyCount ?? 0;
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _validation?.canMove ?? false ? _move : null,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedFolderMoveIn,
          size: 18,
        ),
        label: Text(count == 0 ? 'Create group & move' : 'Move $count media'),
      ),
    ];
  }
}

class _FolderPath extends StatelessWidget {
  const _FolderPath({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
    ),
    child: Row(
      children: [
        const HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({required this.validation});

  final GroupMediaValidation validation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (validation.errorMessage case final message?) {
      return Text(message, style: TextStyle(color: colorScheme.error));
    }
    final issues = [
      ...validation.missingFileNames,
      ...validation.invalidFileNames,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${validation.readyCount} media found',
          style: TextStyle(
            color: validation.readyCount > 0
                ? colorScheme.primary
                : colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (issues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${issues.length} not found or invalid: ${issues.take(3).join(', ')}'
            '${issues.length > 3 ? ', ...' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.error),
          ),
        ],
        if (validation.destinationPath.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Destination: ${validation.destinationPath}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text('$value')],
    ),
  );
}

enum _GroupMediaStage { editing, validating, moving, synchronizing, complete }
