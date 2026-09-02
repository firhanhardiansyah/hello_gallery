import 'package:flutter/material.dart';

class AnimatedGallerySidebar extends StatefulWidget {
  const AnimatedGallerySidebar({
    required this.visible,
    required this.child,
    this.width = defaultWidth,
    this.minWidth = minimumWidth,
    this.maxWidth = maximumWidth,
    this.collapseDragDistance = defaultCollapseDragDistance,
    this.onWidthChanged,
    this.onMinWidthReached,
    super.key,
  }) : assert(minWidth > 0),
       assert(maxWidth >= minWidth),
       assert(collapseDragDistance >= 0),
       assert(width >= minWidth && width <= maxWidth);

  static const duration = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;
  static const defaultWidth = 300.0;
  static const minimumWidth = 250.0;
  static const maximumWidth = 420.0;
  static const defaultCollapseDragDistance = 48.0;

  final bool visible;
  final double width;
  final double minWidth;
  final double maxWidth;
  final double collapseDragDistance;
  final ValueChanged<double>? onWidthChanged;
  final VoidCallback? onMinWidthReached;
  final Widget child;

  @override
  State<AnimatedGallerySidebar> createState() => _AnimatedGallerySidebarState();
}

class _AnimatedGallerySidebarState extends State<AnimatedGallerySidebar>
    with SingleTickerProviderStateMixin {
  double? _dragWidth;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AnimatedGallerySidebar.duration,
    value: widget.visible ? 1 : 0,
  );

  late final Animation<double> _widthFactor = CurvedAnimation(
    parent: _controller,
    curve: AnimatedGallerySidebar.curve,
  );

  @override
  void didUpdateWidget(covariant AnimatedGallerySidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resizable =
        widget.onWidthChanged != null && widget.onMinWidthReached != null;
    return ExcludeSemantics(
      excluding: !widget.visible,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: ClipRect(
          child: SizeTransition(
            axis: Axis.horizontal,
            alignment: Alignment.centerLeft,
            sizeFactor: _widthFactor,
            child: SizedBox(
              width: widget.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.child,
                  if (resizable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _SidebarResizeHandle(
                        onDragStart: () => _dragWidth = widget.width,
                        onDragUpdate: _resize,
                        onDragEnd: _finishResize,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resize(double delta) {
    final nextWidth = (_dragWidth ?? widget.width) + delta;
    _dragWidth = nextWidth;
    widget.onWidthChanged?.call(
      nextWidth.clamp(widget.minWidth, widget.maxWidth).toDouble(),
    );
  }

  void _finishResize() {
    final dragWidth = _dragWidth;
    _dragWidth = null;
    final collapseThreshold = widget.minWidth - widget.collapseDragDistance;
    if (dragWidth != null && dragWidth <= collapseThreshold) {
      widget.onMinWidthReached?.call();
    }
  }
}

class _SidebarResizeHandle extends StatelessWidget {
  const _SidebarResizeHandle({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  static const _hitAreaWidth = 8.0;

  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeLeftRight,
    child: GestureDetector(
      key: const ValueKey('gallery-sidebar-resize-handle'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => onDragStart(),
      onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
      onHorizontalDragEnd: (_) => onDragEnd(),
      onHorizontalDragCancel: onDragEnd,
      child: SizedBox(
        width: _hitAreaWidth,
        height: double.infinity,
      ),
    ),
  );
}
