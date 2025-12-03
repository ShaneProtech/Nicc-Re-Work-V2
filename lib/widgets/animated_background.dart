import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(_controller.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animation;

  BackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Background gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0F0F1E),
        const Color(0xFF1A1A2E),
        const Color(0xFF0F0F1E),
      ],
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Animated circles
    _drawAnimatedCircles(canvas, size);
  }

  void _drawAnimatedCircles(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final circles = [
      {
        'x': 0.2,
        'y': 0.3,
        'radius': 150.0,
        'color': const Color(0xFF00B4D8).withOpacity(0.05),
        'speed': 1.0
      },
      {
        'x': 0.7,
        'y': 0.6,
        'radius': 200.0,
        'color': const Color(0xFF0077B6).withOpacity(0.04),
        'speed': 0.7
      },
      {
        'x': 0.5,
        'y': 0.8,
        'radius': 120.0,
        'color': const Color(0xFF023E8A).withOpacity(0.06),
        'speed': 1.3
      },
    ];

    for (var circle in circles) {
      final x = size.width * (circle['x'] as double) +
          math.sin(animation * 2 * math.pi * (circle['speed'] as double)) * 50;
      final y = size.height * (circle['y'] as double) +
          math.cos(animation * 2 * math.pi * (circle['speed'] as double)) * 50;

      paint.color = circle['color'] as Color;
      canvas.drawCircle(
        Offset(x, y),
        circle['radius'] as double,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}



