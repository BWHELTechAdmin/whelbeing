import 'package:flutter/material.dart';

/// A widget that applies a gold shimmer/shine effect to its child.
///
/// The shimmer sweeps a warm gold highlight across the child widget
/// in a continuous loop, creating a subtle luxurious metallic shine.
class GoldShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const GoldShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<GoldShimmer> createState() => _GoldShimmerState();
}

class _GoldShimmerState extends State<GoldShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final double slide = _controller.value * 2.0 - 0.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFC9A96E), // Muted gold
                Color(0xFFE8D5A8), // Warm highlight
                Color(0xFFC9A96E), // Muted gold
              ],
              stops: [
                (slide - 0.2).clamp(0.0, 1.0),
                slide.clamp(0.0, 1.0),
                (slide + 0.2).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// A container with a warm gold-to-black gradient background and a subtle
/// shimmer overlay. Designed for dark mode luxury aesthetic.
///
/// Use this for hero sections like the cycle tracker, profile header, and
/// community stats cards.
class GoldShimmerContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const GoldShimmerContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<GoldShimmerContainer> createState() => _GoldShimmerContainerState();
}

class _GoldShimmerContainerState extends State<GoldShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double slide = _controller.value * 2.0 - 0.5;
        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFF3D2E14), // Warm dark gold
                Color(0xFF1A1200), // Very dark warm brown
                Color(0xFF0D0D0D), // Near black
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: const Color(0xFF3D2E14).withValues(alpha: 0.4),
            ),
          ),
          child: Stack(
            children: [
              // Subtle shimmer sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: CustomPaint(
                    painter: _ShimmerPainter(slide),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double slide;

  _ShimmerPainter(this.slide);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFFC9A96E).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: [
          (slide - 0.2).clamp(0.0, 1.0),
          slide.clamp(0.0, 1.0),
          (slide + 0.2).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.slide != slide;
  }
}
