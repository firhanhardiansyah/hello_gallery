import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

class ChooseFolderPrompt extends StatelessWidget {
  const ChooseFolderPrompt({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HugeIcon(icon: HugeIcons.strokeRoundedImageComposition, size: 72),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Choose a folder to start',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: onPressed,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedFolderOpen),
          label: const Text('Choose root folder'),
        ),
      ],
    ),
  );
}
