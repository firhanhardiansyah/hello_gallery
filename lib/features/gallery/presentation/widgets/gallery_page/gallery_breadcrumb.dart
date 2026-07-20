import 'package:flutter/material.dart';
import 'package:hello_gallery/core/theme/app_spacing.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path/path.dart' as path;

class GalleryBreadcrumb extends StatelessWidget {
  const GalleryBreadcrumb({
    required this.rootPath,
    required this.currentPath,
    required this.onPathSelected,
    super.key,
  });

  final String? rootPath;
  final String? currentPath;
  final ValueChanged<String> onPathSelected;

  @override
  Widget build(BuildContext context) {
    final segments = _segments();
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < segments.length; index++) ...[
            if (index > 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _BreadcrumbSegment(
                item: segments[index],
                current: _isCurrent(segments[index].folderPath),
                onTap: onPathSelected,
              ),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  List<_BreadcrumbItem> _segments() {
    final root = rootPath;
    if (root == null || root.isEmpty) {
      return const [_BreadcrumbItem(label: 'Gallery')];
    }

    final segments = <_BreadcrumbItem>[
      _BreadcrumbItem(label: _displayName(root), folderPath: root),
    ];
    final current = currentPath;
    if (current == null || path.equals(root, current)) return segments;
    if (!path.isWithin(root, current)) {
      return [
        _BreadcrumbItem(label: _displayName(current), folderPath: current),
      ];
    }

    final relativePath = path.relative(current, from: root);
    var segmentPath = root;
    for (final part in path.split(relativePath).where((part) => part != '.')) {
      segmentPath = path.join(segmentPath, part);
      segments.add(_BreadcrumbItem(label: part, folderPath: segmentPath));
    }
    return segments;
  }

  bool _isCurrent(String? folderPath) {
    final current = currentPath;
    return folderPath == null ||
        current == null ||
        path.equals(folderPath, current);
  }

  String _displayName(String value) {
    final name = path.basename(path.normalize(value));
    return name.isEmpty ? value : name;
  }
}

class _BreadcrumbSegment extends StatelessWidget {
  const _BreadcrumbSegment({
    required this.item,
    required this.current,
    required this.onTap,
  });

  final _BreadcrumbItem item;
  final bool current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final folderPath = item.folderPath;
    final colorScheme = Theme.of(context).colorScheme;
    final text = Text(
      item.label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: current ? colorScheme.onSurface : colorScheme.primary,
        fontWeight: current ? FontWeight.w500 : FontWeight.w400,
      ),
    );
    if (current || folderPath == null) return text;
    return Tooltip(
      message: folderPath,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        onTap: () => onTap(folderPath),
        child: text,
      ),
    );
  }
}

class _BreadcrumbItem {
  const _BreadcrumbItem({required this.label, this.folderPath});

  final String label;
  final String? folderPath;
}
