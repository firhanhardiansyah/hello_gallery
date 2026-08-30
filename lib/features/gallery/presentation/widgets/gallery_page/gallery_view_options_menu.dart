import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../settings/presentation/notifiers/settings_notifier.dart';
import '../../../domain/value_objects/gallery_layout_mode.dart';
import '../../../domain/value_objects/gallery_sort.dart';
import '../../../domain/value_objects/gallery_style_level.dart';
import '../../notifiers/gallery_notifier.dart';

enum _GalleryViewOption {
  nameAscending,
  nameDescending,
  newest,
  oldest,
  showItemNames,
  hideItemNames,
  gridLayout,
  aspectRatioGridLayout,
  quiltedLayout,
  masonryLayout,
  customizeGallery,
}

class GalleryViewOptionsMenu extends ConsumerWidget {
  const GalleryViewOptionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryNotifierProvider);
    final sort = gallery.sort;
    final showItemNames = ref.watch(
      settingsNotifierProvider.select((settings) => settings.showItemNames),
    );
    final layoutMode = ref.watch(
      settingsNotifierProvider.select((settings) => settings.galleryLayoutMode),
    );

    return PopupMenuButton<_GalleryViewOption>(
      tooltip: 'View options',
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedFilterMail),
      onSelected: (option) => _applyOption(context, ref, option),
      itemBuilder: (context) => [
        const PopupMenuItem<_GalleryViewOption>(
          enabled: false,
          height: 32,
          child: Text('Sort by'),
        ),
        _item(
          option: _GalleryViewOption.nameAscending,
          label: GallerySort.nameAscending.label,
          icon: HugeIcons.strokeRoundedSortingAZ01,
          selected: sort == GallerySort.nameAscending,
          enabled: gallery.canManageDirectory,
        ),
        _item(
          option: _GalleryViewOption.nameDescending,
          label: GallerySort.nameDescending.label,
          icon: HugeIcons.strokeRoundedSortingZA01,
          selected: sort == GallerySort.nameDescending,
          enabled: gallery.canManageDirectory,
        ),
        _item(
          option: _GalleryViewOption.newest,
          label: GallerySort.newest.label,
          icon: HugeIcons.strokeRoundedSortByDown01,
          selected: sort == GallerySort.newest,
          enabled: gallery.canManageDirectory,
        ),
        _item(
          option: _GalleryViewOption.oldest,
          label: GallerySort.oldest.label,
          icon: HugeIcons.strokeRoundedSortByUp01,
          selected: sort == GallerySort.oldest,
          enabled: gallery.canManageDirectory,
        ),
        PopupMenuDivider(indent: AppSpacing.md, endIndent: AppSpacing.md),
        const PopupMenuItem<_GalleryViewOption>(
          enabled: false,
          height: 32,
          child: Text('Item names'),
        ),
        _item(
          option: _GalleryViewOption.showItemNames,
          label: 'Show item names',
          icon: HugeIcons.strokeRoundedView,
          selected: showItemNames,
        ),
        _item(
          option: _GalleryViewOption.hideItemNames,
          label: 'Hide item names',
          icon: HugeIcons.strokeRoundedViewOff,
          selected: !showItemNames,
        ),
        PopupMenuDivider(indent: AppSpacing.md, endIndent: AppSpacing.md),
        const PopupMenuItem<_GalleryViewOption>(
          enabled: false,
          height: 32,
          child: Text('Layout'),
        ),
        _item(
          option: _GalleryViewOption.gridLayout,
          label: 'Grid',
          icon: HugeIcons.strokeRoundedGridView,
          selected: layoutMode == GalleryLayoutMode.grid,
        ),
        _item(
          option: _GalleryViewOption.aspectRatioGridLayout,
          label: 'Aspect Ratio Grid',
          icon: HugeIcons.strokeRoundedImageComposition,
          selected: layoutMode == GalleryLayoutMode.aspectRatioGrid,
        ),
        _item(
          option: _GalleryViewOption.quiltedLayout,
          label: 'Quilted',
          icon: HugeIcons.strokeRoundedLayoutGrid,
          selected: layoutMode == GalleryLayoutMode.quilted,
        ),
        _item(
          option: _GalleryViewOption.masonryLayout,
          label: 'Masonry',
          icon: HugeIcons.strokeRoundedGrid,
          selected: layoutMode == GalleryLayoutMode.masonry,
        ),
        PopupMenuDivider(indent: AppSpacing.md, endIndent: AppSpacing.md),
        _item(
          option: _GalleryViewOption.customizeGallery,
          label: 'Customize gallery…',
          icon: HugeIcons.strokeRoundedSlidersHorizontal,
          selected: false,
        ),
      ],
    );
  }

  void _applyOption(
    BuildContext context,
    WidgetRef ref,
    _GalleryViewOption option,
  ) {
    switch (option) {
      case _GalleryViewOption.nameAscending:
        _setSort(ref, GallerySort.nameAscending);
      case _GalleryViewOption.nameDescending:
        _setSort(ref, GallerySort.nameDescending);
      case _GalleryViewOption.newest:
        _setSort(ref, GallerySort.newest);
      case _GalleryViewOption.oldest:
        _setSort(ref, GallerySort.oldest);
      case _GalleryViewOption.showItemNames:
        unawaited(
          ref.read(settingsNotifierProvider.notifier).setShowItemNames(true),
        );
      case _GalleryViewOption.hideItemNames:
        unawaited(
          ref.read(settingsNotifierProvider.notifier).setShowItemNames(false),
        );
      case _GalleryViewOption.gridLayout:
        unawaited(
          ref
              .read(settingsNotifierProvider.notifier)
              .setGalleryLayoutMode(GalleryLayoutMode.grid),
        );
      case _GalleryViewOption.aspectRatioGridLayout:
        unawaited(
          ref
              .read(settingsNotifierProvider.notifier)
              .setGalleryLayoutMode(GalleryLayoutMode.aspectRatioGrid),
        );
      case _GalleryViewOption.quiltedLayout:
        unawaited(
          ref
              .read(settingsNotifierProvider.notifier)
              .setGalleryLayoutMode(GalleryLayoutMode.quilted),
        );
      case _GalleryViewOption.masonryLayout:
        unawaited(
          ref
              .read(settingsNotifierProvider.notifier)
              .setGalleryLayoutMode(GalleryLayoutMode.masonry),
        );
      case _GalleryViewOption.customizeGallery:
        unawaited(
          showDialog<void>(
            context: context,
            builder: (context) => const _CustomizeGalleryDialog(),
          ),
        );
    }
  }

  void _setSort(WidgetRef ref, GallerySort sort) {
    ref.read(galleryNotifierProvider.notifier).setSort(sort);
    unawaited(ref.read(settingsNotifierProvider.notifier).setGallerySort(sort));
  }

  PopupMenuItem<_GalleryViewOption> _item({
    required _GalleryViewOption option,
    required String label,
    required List<List<dynamic>> icon,
    required bool selected,
    bool enabled = true,
  }) {
    return PopupMenuItem(
      value: option,
      enabled: enabled,
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label)),
          if (selected)
            const HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 18),
        ],
      ),
    );
  }
}

class _CustomizeGalleryDialog extends ConsumerWidget {
  const _CustomizeGalleryDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final usesDefaults =
        settings.galleryGridSpacing == GalleryStyleLevel.standard &&
        settings.galleryCornerRadius == GalleryStyleLevel.standard;

    return AlertDialog(
      title: const Text('Customize gallery'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GalleryStyleSlider(
              title: 'Item spacing',
              value: settings.galleryGridSpacing,
              onChanged: (level) =>
                  unawaited(notifier.setGalleryGridSpacing(level)),
            ),
            const SizedBox(height: AppSpacing.lg),
            _GalleryStyleSlider(
              title: 'Corner radius',
              value: settings.galleryCornerRadius,
              onChanged: (level) =>
                  unawaited(notifier.setGalleryCornerRadius(level)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: usesDefaults
              ? null
              : () => unawaited(notifier.resetGalleryStyle()),
          child: const Text('Reset to defaults'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _GalleryStyleSlider extends StatelessWidget {
  const _GalleryStyleSlider({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final GalleryStyleLevel value;
  final ValueChanged<GalleryStyleLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: textTheme.titleSmall)),
            Text(value.label, style: textTheme.labelLarge),
          ],
        ),
        Slider(
          value: value.index.toDouble(),
          min: 0,
          max: (GalleryStyleLevel.values.length - 1).toDouble(),
          divisions: GalleryStyleLevel.values.length - 1,
          label: value.label,
          semanticFormatterCallback: (_) => value.label,
          onChanged: (rawValue) =>
              onChanged(GalleryStyleLevel.values[rawValue.round()]),
        ),
        Row(
          children: [
            for (final level in GalleryStyleLevel.values)
              Expanded(
                child: Text(
                  level.label,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
