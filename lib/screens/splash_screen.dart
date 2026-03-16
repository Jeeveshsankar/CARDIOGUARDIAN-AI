import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cardioguardian/core/app_theme.dart';
import 'package:cardioguardian/screens/main_navigation.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _textController;
  late AnimationController _particleController;

  late Animation<double> _fadeIn;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _loaderOpacity;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _textSlide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textController, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)));
    _loaderOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });

    Future.delayed(const Duration(milliseconds: 4000), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionDuration: const Duration(milliseconds: 1000),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orbSize = size.width.clamp(240.0, 400.0) * 0.7;

    return Scaffold(
      backgroundColor: const Color(0xFF010101),
      body: AnimatedBuilder(
        animation: Listenable.merge([_orbController, _pulseController, _fadeController, _textController, _particleController]),
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundPainter(
                    progress: _orbController.value,
                    pulse: _pulseController.value,
                    centerY: size.height * 0.4,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticleFieldPainter(
                    progress: _particleController.value,
                    opacity: _fadeIn.value,
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: SizedBox(
                          width: orbSize,
                          height: orbSize,
                          child: CustomPaint(
                            painter: _OrbPainter(
                              rotation: _orbController.value * 2 * pi,
                              pulse: _pulseController.value,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                "CardioGuardian",
                                style: GoogleFonts.outfit(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AppTheme.primaryColor, Color(0xFFFF5E7E)],
                                ).createShader(bounds),
                                child: Text(
                                  "AI",
                                  style: GoogleFonts.outfit(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _subtitleOpacity.value,
                        child: Text(
                          "PRECISION HEART MONITORING",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white38,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      Opacity(
                        opacity: _loaderOpacity.value,
                        child: SizedBox(
                          width: 180,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white10,
                              color: AppTheme.primaryColor,
                              minHeight: 2,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double centerY;

  _BackgroundPainter({required this.progress, required this.pulse, required this.centerY});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, centerY);
    final glowRadius = 200 + pulse * 40;
    
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.08 + pulse * 0.04),
          AppTheme.primaryColor.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, paint);

    final secondaryPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF5856D6).withValues(alpha: 0.04), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center + const Offset(60, 80), radius: 240));
    canvas.drawCircle(center + const Offset(60, 80), 240, secondaryPaint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => true;
}

class _ParticleFieldPainter extends CustomPainter {
  final double progress;
  final double opacity;
  static final List<_Particle> _particles = _generateParticles(60);

  _ParticleFieldPainter({required this.progress, required this.opacity});

  static List<_Particle> _generateParticles(int count) {
    final rng = Random(42);
    return List.generate(count, (_) => _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 0.8 + rng.nextDouble() * 1.8,
      speed: 0.2 + rng.nextDouble() * 0.8,
      offset: rng.nextDouble() * 2 * pi,
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.01) return;
    for (final p in _particles) {
      final angle = progress * 2 * pi * p.speed + p.offset;
      final dx = p.x * size.width + sin(angle) * 15;
      final dy = (p.y * size.height + progress * p.speed * 120) % size.height;
      final alpha = (0.15 + sin(angle) * 0.1).clamp(0.0, 1.0) * opacity;
      canvas.drawCircle(Offset(dx, dy), p.size, Paint()..color = Colors.white.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter old) => true;
}

class _Particle {
  final double x, y, size, speed, offset;
  const _Particle({required this.x, required this.y, required this.size, required this.speed, required this.offset});
}

class _OrbPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  _OrbPainter({required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4 + pulse * 4;

    _drawOuterRings(canvas, center, radius);
    _drawOrb(canvas, center, radius * 0.75);
    _drawWireframe(canvas, center, radius * 0.75);
    _drawHeartIcon(canvas, center, radius * 0.32);
    _drawOrbitDots(canvas, center, radius);
  }

  void _drawOuterRings(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius + i * 15;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = AppTheme.primaryColor.withValues(alpha: 0.08 - i * 0.02);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation * (0.3 + i * 0.15));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: ringRadius * 2, height: ringRadius * 1.5), paint);
      canvas.restore();
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          const Color(0xFFFF4060).withValues(alpha: 0.3 + pulse * 0.1),
          const Color(0xFFFF2D55).withValues(alpha: 0.1),
          const Color(0xFF5856D6).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        startAngle: rotation,
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.6),
          AppTheme.primaryColor.withValues(alpha: 0.0),
          const Color(0xFF5856D6).withValues(alpha: 0.3),
          AppTheme.primaryColor.withValues(alpha: 0.0),
          AppTheme.primaryColor.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawWireframe(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (int i = 0; i < 6; i++) {
      final angle = rotation + (i * pi / 6);
      final yScale = cos(angle) * 0.9;
      paint.color = AppTheme.primaryColor.withValues(alpha: (0.08 + yScale.abs() * 0.08));
      canvas.drawOval(Rect.fromCenter(center: Offset(0, sin(angle) * radius * 0.1), width: radius * 2, height: radius * yScale.abs() * 1.8), paint);
    }
    canvas.restore();
  }

  void _drawHeartIcon(Canvas canvas, Offset center, double s) {
    final path = Path();
    path.moveTo(center.dx, center.dy + s * 0.7);
    path.cubicTo(center.dx - s * 1.2, center.dy - s * 0.2, center.dx - s * 0.6, center.dy - s * 0.9, center.dx, center.dy - s * 0.4);
    path.cubicTo(center.dx + s * 0.6, center.dy - s * 0.9, center.dx + s * 1.2, center.dy - s * 0.2, center.dx, center.dy + s * 0.7);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.9), AppTheme.primaryColor.withValues(alpha: 0.8)],
      ).createShader(Rect.fromCenter(center: center, width: s * 2, height: s * 2));
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, s * 1.3, Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.15 + pulse * 0.1), Colors.transparent]).createShader(Rect.fromCircle(center: center, radius: s * 1.5)));
  }

  void _drawOrbitDots(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 4; i++) {
      final angle = rotation * 1.5 + i * (pi / 2);
      final dx = center.dx + (radius * 1.1) * cos(angle);
      final dy = center.dy + (radius * 1.1) * sin(angle) * cos(pi / 6);
      canvas.drawCircle(Offset(dx, dy), 3.0, Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(dx, dy), 8.0, Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.1));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => true;
}
