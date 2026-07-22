import 'package:flutter/material.dart';

class AnimatedGallerySidebar extends StatefulWidget {
  const AnimatedGallerySidebar({
    required this.visible,
    required this.child,
    this.width = 300,
    super.key,
  });

  static const duration = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;

  final bool visible;
  final double width;
  final Widget child;

  @override
  State<AnimatedGallerySidebar> createState() => _AnimatedGallerySidebarState();
}

class _AnimatedGallerySidebarState extends State<AnimatedGallerySidebar>
    with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) => ExcludeSemantics(
    excluding: !widget.visible,
    child: IgnorePointer(
      ignoring: !widget.visible,
      child: ClipRect(
        child: SizeTransition(
          axis: Axis.horizontal,
          axisAlignment: -1,
          sizeFactor: _widthFactor,
          child: SizedBox(width: widget.width, child: widget.child),
        ),
      ),
    ),
  );
}
