import 'package:flutter/material.dart';

/// Rakshak Pulse Animation Widget
/// Expanding circle animation for SOS button
class RkPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;

  const RkPulse({
    super.key,
    required this.child,
    required this.color,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<RkPulse> createState() => _RkPulseState();
}

class _RkPulseState extends State<RkPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse rings
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 120 * _scaleAnimation.value,
              height: 120 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(_opacityAnimation.value),
                  width: 2,
                ),
              ),
            );
          },
        ),
        // Child widget
        widget.child,
      ],
    );
  }
}
