import 'package:flutter/material.dart';

/// Premium luxury gold loading indicator.
/// A thin glowing gold line that shimmers — feels premium and minimal.
class PremiumLoadingIndicator extends StatefulWidget {
  final double width;
  final Color? color;

  const PremiumLoadingIndicator({
    super.key,
    this.width = 180,
    this.color,
  });

  @override
  State<PremiumLoadingIndicator> createState() => _PremiumLoadingIndicatorState();
}

class _PremiumLoadingIndicatorState extends State<PremiumLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = widget.color ?? const Color(0xFFD4AF37);

    return SizedBox(
      width: widget.width,
      height: 3,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  goldColor.withOpacity(0.3),
                  goldColor,
                  goldColor.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: [
                  (_shimmerController.value - 0.4).clamp(0.0, 1.0),
                  (_shimmerController.value - 0.15).clamp(0.0, 1.0),
                  _shimmerController.value,
                  (_shimmerController.value + 0.15).clamp(0.0, 1.0),
                  (_shimmerController.value + 0.4).clamp(0.0, 1.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: goldColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Animated "breathing" dot indicator for premium feel.
class PremiumDotsIndicator extends StatefulWidget {
  final Color color;
  final int dotCount;

  const PremiumDotsIndicator({
    super.key,
    this.color = const Color(0xFFD4AF37),
    this.dotCount = 3,
  });

  @override
  State<PremiumDotsIndicator> createState() => _PremiumDotsIndicatorState();
}

class _PremiumDotsIndicatorState extends State<PremiumDotsIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.dotCount, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(_animations[i].value),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_animations[i].value * 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}