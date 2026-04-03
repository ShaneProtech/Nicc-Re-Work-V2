import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final bool showParticles;
  final bool showGrid;
  
  const AnimatedBackground({
    super.key,
    this.showParticles = true,
    this.showGrid = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late List<_Particle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _primaryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    
    _secondaryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _particles = List.generate(
      widget.showParticles ? 30 : 0,
      (_) => _Particle.random(_random),
    );
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_primaryController, _secondaryController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _NeumorphicBackgroundPainter(
            primaryAnimation: _primaryController.value,
            secondaryAnimation: _secondaryController.value,
            particles: _particles,
            showParticles: widget.showParticles,
            showGrid: widget.showGrid,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double phase;
  
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.phase,
  });
  
  factory _Particle.random(math.Random random) {
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      speed: 0.2 + random.nextDouble() * 0.6,
      size: 1.5 + random.nextDouble() * 3,
      opacity: 0.1 + random.nextDouble() * 0.4,
      phase: random.nextDouble() * math.pi * 2,
    );
  }
}

class _NeumorphicBackgroundPainter extends CustomPainter {
  final double primaryAnimation;
  final double secondaryAnimation;
  final List<_Particle> particles;
  final bool showParticles;
  final bool showGrid;

  _NeumorphicBackgroundPainter({
    required this.primaryAnimation,
    required this.secondaryAnimation,
    required this.particles,
    required this.showParticles,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    if (showGrid) _drawSubtleGrid(canvas, size);
    _drawGlowingOrbs(canvas, size);
    if (showParticles) _drawFloatingParticles(canvas, size);
    _drawVignette(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint();
    
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.backgroundDark,
        AppColors.backgroundMedium.withOpacity(0.7),
        AppColors.backgroundDark,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawSubtleGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.shadowLight.withOpacity(0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 60.0;
    final offset = (primaryAnimation * gridSize) % gridSize;
    
    for (double x = -gridSize + offset; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = -gridSize + offset; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawGlowingOrbs(Canvas canvas, Size size) {
    final orbs = [
      {
        'x': 0.15,
        'y': 0.25,
        'radius': 250.0,
        'color': AppColors.primaryBlue,
        'speed': 0.4,
        'opacity': 0.06,
      },
      {
        'x': 0.85,
        'y': 0.35,
        'radius': 180.0,
        'color': AppColors.cardAI,
        'speed': 0.6,
        'opacity': 0.05,
      },
      {
        'x': 0.5,
        'y': 0.75,
        'radius': 200.0,
        'color': AppColors.primaryBlueDark,
        'speed': 0.3,
        'opacity': 0.07,
      },
      {
        'x': 0.75,
        'y': 0.85,
        'radius': 160.0,
        'color': AppColors.cardLibrary,
        'speed': 0.5,
        'opacity': 0.04,
      },
    ];

    for (var orb in orbs) {
      final speed = orb['speed'] as double;
      final baseX = orb['x'] as double;
      final baseY = orb['y'] as double;
      
      final x = size.width * baseX +
          math.sin(primaryAnimation * math.pi * 2 * speed) * 40 +
          math.cos(secondaryAnimation * math.pi * 2 * speed * 1.3) * 20;
      final y = size.height * baseY +
          math.cos(primaryAnimation * math.pi * 2 * speed) * 30 +
          math.sin(secondaryAnimation * math.pi * 2 * speed * 0.7) * 25;

      final gradient = RadialGradient(
        colors: [
          (orb['color'] as Color).withOpacity(orb['opacity'] as double),
          (orb['color'] as Color).withOpacity(0),
        ],
        stops: const [0.0, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(
            center: Offset(x, y),
            radius: orb['radius'] as double,
          ),
        );

      canvas.drawCircle(
        Offset(x, y),
        orb['radius'] as double,
        paint,
      );
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var particle in particles) {
      final animPhase = (primaryAnimation * particle.speed + particle.phase) % 1.0;
      
      final x = size.width * particle.x + math.sin(animPhase * math.pi * 2) * 30;
      final y = size.height * ((particle.y + animPhase * 0.3) % 1.0);
      
      final pulseOpacity = particle.opacity * 
          (0.5 + 0.5 * math.sin(secondaryAnimation * math.pi * 2 + particle.phase));
      
      paint.color = AppColors.primaryBlue.withOpacity(pulseOpacity);
      
      canvas.drawCircle(Offset(x, y), particle.size, paint);
      
      paint.color = AppColors.primaryBlue.withOpacity(pulseOpacity * 0.3);
      canvas.drawCircle(Offset(x, y), particle.size * 2, paint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        AppColors.backgroundDark.withOpacity(0.4),
      ],
      stops: const [0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_NeumorphicBackgroundPainter oldDelegate) {
    return primaryAnimation != oldDelegate.primaryAnimation ||
        secondaryAnimation != oldDelegate.secondaryAnimation;
  }
}



