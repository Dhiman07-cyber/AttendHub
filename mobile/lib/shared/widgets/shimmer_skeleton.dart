import 'package:flutter/material.dart';

/// A sleek, high-performance shimmer animation provider.
/// Follows Supabase/Vercel minimal design aesthetics with warm off-white tones.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  static ShimmerLoadingState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerLoadingState>();
  }

  @override
  State<ShimmerLoading> createState() => ShimmerLoadingState();
}

class ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Listenable get shimmerAnimation => _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A single skeleton placeholder element with smooth animated shimmer gradient.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  const SkeletonBox.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  const SkeletonBox.text({
    super.key,
    this.width,
    this.height = 13.0,
    this.margin,
  })  : shape = BoxShape.rectangle,
        borderRadius = const BorderRadius.all(Radius.circular(6));

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = ShimmerLoading.of(context);
    if (parent == null && _localController == null) {
      _localController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parent = ShimmerLoading.of(context);
    final animation = parent?.shimmerAnimation ?? _localController!;

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final val = (animation as Animation<double>).value;
          return Container(
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : (widget.borderRadius ?? BorderRadius.circular(8)),
              gradient: LinearGradient(
                begin: Alignment(-2.0 + (4.0 * val), 0.0),
                end: Alignment(-0.5 + (4.0 * val), 0.0),
                stops: const [0.0, 0.5, 1.0],
                colors: const [
                  Color(0xFFEBE5DF),
                  Color(0xFFF7F3EE),
                  Color(0xFFEBE5DF),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
