import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../settings/presentation/notifiers/settings_notifier.dart';

class GalleryViewOptionsMenu extends ConsumerWidget {
  const GalleryViewOptionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showItemNames = ref.watch(
      settingsNotifierProvider.select((settings) => settings.showItemNames),
    );
    return PopupMenuButton<Never>(
      tooltip: 'View options',
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedLayoutGrid),
      itemBuilder: (context) => [
        _GalleryViewSwitchEntry(
          value: showItemNames,
          onChanged: (value) {
            unawaited(
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setShowItemNames(value),
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _GalleryViewSwitchEntry extends PopupMenuEntry<Never> {
  const _GalleryViewSwitchEntry({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(Never? value) => false;

  @override
  State<_GalleryViewSwitchEntry> createState() =>
      _GalleryViewSwitchEntryState();
}

class _GalleryViewSwitchEntryState extends State<_GalleryViewSwitchEntry> {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: widget.height),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedEye, size: 20),
          const SizedBox(width: AppSpacing.md),
          const Expanded(child: Text('Show item names')),
          Switch(value: widget.value, onChanged: widget.onChanged),
        ],
      ),
    ),
  );
}
