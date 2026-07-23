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
import 'gallery_navigation_controls.dart';
import 'gallery_view_options_menu.dart';

class GalleryShellTopBar extends ConsumerWidget {
  const GalleryShellTopBar({
    required this.gallery,
    required this.isPreview,
    required this.isFullscreen,
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
    required this.selectedMediaCount,
    required this.onDeleteSelectedMedia,
    this.windowPlatform,
    super.key,
  });

  final GalleryUiState gallery;
  final bool isPreview;
  final bool isFullscreen;
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
  final int selectedMediaCount;
  final VoidCallback onDeleteSelectedMedia;
  final DesktopWindowPlatform? windowPlatform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelecting = !isPreview && selectedItemCount > 0;
    final platform = windowPlatform ?? currentDesktopWindowPlatform;
    return DecoratedBox(
      key: const ValueKey('gallery-shell-top-bar-border'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: .3),
        ),
      ),
      child: DesktopWindowTitleBar(
        platform: platform,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        reserveMacOSWindowButtons: !sidebarVisible,
        showWindowsCaptionControls: !isFullscreen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              GalleryNavigationControls(
                sidebarVisible: sidebarVisible,
                onToggleSidebar: onToggleSidebar,
                backTooltip: isPreview ? 'Back to gallery' : 'Back',
                onBack: isPreview
                    ? onClosePreview
                    : gallery.canGoBack
                    ? ref.read(galleryNotifierProvider.notifier).goBack
                    : null,
                onForward: !isPreview && gallery.canGoForward
                    ? ref.read(galleryNotifierProvider.notifier).goForward
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isSelecting)
                ..._buildSelectionActions(context)
              else ...[
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
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                  ),
                ] else ...[
                  IconButton(
                    tooltip: 'New folder',
                    onPressed:
                        gallery.currentPath != null &&
                            gallery.canManageDirectory
                        ? onCreateFolder
                        : null,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedFolderAdd,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Group media',
                    onPressed: gallery.isReady ? onGroupMedia : null,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedFolderMoveIn,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (gallery.canManageDirectory)
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
                  const GalleryViewOptionsMenu(),
                  const SizedBox(width: AppSpacing.xs),
                  const AppearanceThemeMenu(),
                ],
              ],
            ],
          ),
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
    IconButton(
      key: const ValueKey('delete-selected-media-button'),
      tooltip: selectedMediaCount == 1
          ? 'Move selected file to Trash'
          : 'Move selected files to Trash',
      onPressed: selectedMediaCount > 0 ? onDeleteSelectedMedia : null,
      color: Theme.of(context).colorScheme.error,
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
    ),
    const SizedBox(width: AppSpacing.xs),
  ];
}
