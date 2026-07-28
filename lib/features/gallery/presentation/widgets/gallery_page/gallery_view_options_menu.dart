import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../settings/presentation/notifiers/settings_notifier.dart';
import '../../../domain/value_objects/gallery_layout_mode.dart';
import '../../../domain/value_objects/gallery_sort.dart';
import '../../notifiers/gallery_notifier.dart';

enum _GalleryViewOption {
  nameAscending,
  nameDescending,
  newest,
  oldest,
  showItemNames,
  hideItemNames,
  gridLayout,
  quiltedLayout,
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
      onSelected: (option) => _applyOption(ref, option),
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
          option: _GalleryViewOption.quiltedLayout,
          label: 'Quilted',
          icon: HugeIcons.strokeRoundedLayoutGrid,
          selected: layoutMode == GalleryLayoutMode.quilted,
        ),
      ],
    );
  }

  void _applyOption(WidgetRef ref, _GalleryViewOption option) {
    switch (option) {
      case _GalleryViewOption.nameAscending:
        ref
            .read(galleryNotifierProvider.notifier)
            .setSort(GallerySort.nameAscending);
      case _GalleryViewOption.nameDescending:
        ref
            .read(galleryNotifierProvider.notifier)
            .setSort(GallerySort.nameDescending);
      case _GalleryViewOption.newest:
        ref.read(galleryNotifierProvider.notifier).setSort(GallerySort.newest);
      case _GalleryViewOption.oldest:
        ref.read(galleryNotifierProvider.notifier).setSort(GallerySort.oldest);
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
      case _GalleryViewOption.quiltedLayout:
        unawaited(
          ref
              .read(settingsNotifierProvider.notifier)
              .setGalleryLayoutMode(GalleryLayoutMode.quilted),
        );
    }
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
