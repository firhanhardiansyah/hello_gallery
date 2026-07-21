import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hello_gallery/core/widgets/desktop_window_title_bar.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../domain/value_objects/gallery_sort.dart';
import '../../notifiers/gallery_notifier.dart';
import '../../states/gallery_ui_state.dart';
import 'appearance_theme_menu.dart';
import 'gallery_breadcrumb.dart';

class GalleryShellTopBar extends ConsumerWidget {
  const GalleryShellTopBar({
    required this.gallery,
    required this.isPreview,
    required this.previewTitle,
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.onClosePreview,
    required this.onGroupMedia,
    required this.onCreateFolder,
    required this.selectedItemCount,
    required this.totalItemCount,
    required this.onSelectAll,
    required this.onClearSelection,
    super.key,
  });

  final GalleryUiState gallery;
  final bool isPreview;
  final String? previewTitle;
  final bool sidebarVisible;
  final VoidCallback onToggleSidebar;
  final VoidCallback onClosePreview;
  final VoidCallback onGroupMedia;
  final VoidCallback onCreateFolder;
  final int selectedItemCount;
  final int totalItemCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelecting = !isPreview && selectedItemCount > 0;
    return DesktopWindowTitleBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      reserveMacOSWindowButtons: !sidebarVisible,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: isSelecting
              ? _buildSelectionActions(context)
              : [
                  IconButton(
                    tooltip: sidebarVisible ? 'Hide sidebar' : 'Show sidebar',
                    onPressed: onToggleSidebar,
                    icon: HugeIcon(
                      icon: sidebarVisible
                          ? HugeIcons.strokeRoundedSidebarLeft
                          : HugeIcons.strokeRoundedPanelLeftOpen,
                    ),
                  ),
                  IconButton(
                    tooltip: isPreview ? 'Back to gallery' : 'Back',
                    onPressed: isPreview
                        ? onClosePreview
                        : gallery.canGoBack
                        ? ref.read(galleryNotifierProvider.notifier).goBack
                        : null,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft02,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Forward',
                    onPressed: !isPreview && gallery.canGoForward
                        ? ref.read(galleryNotifierProvider.notifier).goForward
                        : null,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight02,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: isPreview
                        ? Text(
                            previewTitle ?? 'Media detail',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          )
                        : GalleryBreadcrumb(
                            rootPath: gallery.rootPath,
                            currentPath: gallery.currentPath,
                            onPathSelected: ref
                                .read(galleryNotifierProvider.notifier)
                                .openDirectory,
                          ),
                  ),

                  if (isPreview) ...[
                    IconButton(
                      tooltip: 'Close detail',
                      onPressed: onClosePreview,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      tooltip: 'New folder',
                      onPressed:
                          gallery.currentPath != null &&
                              (gallery.status == GalleryStatus.ready ||
                                  gallery.status == GalleryStatus.empty)
                          ? onCreateFolder
                          : null,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFolderAdd,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Group media',
                      onPressed: gallery.status == GalleryStatus.ready
                          ? onGroupMedia
                          : null,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFolderMoveIn,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (gallery.status == GalleryStatus.ready ||
                        gallery.status == GalleryStatus.empty)
                      DropdownButtonHideUnderline(
                        child: DropdownButton<GallerySort>(
                          value: gallery.sort,
                          items: [
                            for (final sort in GallerySort.values)
                              DropdownMenuItem(
                                value: sort,
                                child: Text(sort.label),
                              ),
                          ],
                          onChanged: (sort) {
                            if (sort != null) {
                              ref
                                  .read(galleryNotifierProvider.notifier)
                                  .setSort(sort);
                            }
                          },
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    const AppearanceThemeMenu(),
                  ],
                ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectionActions(BuildContext context) => [
    IconButton(
      tooltip: 'Clear selection',
      onPressed: onClearSelection,
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
    ),
    const SizedBox(width: AppSpacing.xs),
    Expanded(
      child: Text(
        '$selectedItemCount ${selectedItemCount == 1 ? 'item' : 'items'} selected',
        key: const ValueKey('gallery-selection-count'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
    TextButton(
      onPressed: selectedItemCount < totalItemCount ? onSelectAll : null,
      child: const Text('Select all'),
    ),
    const SizedBox(width: AppSpacing.xs),
  ];
}
