import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/routing/app_router.dart';
import '../../../main.dart';

/// Premium splash screen with animated arrow logo and particle effects.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _arrowController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _arrowDraw;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _arrowDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _startAnimation();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.mainMenu);
      }
    });
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _arrowController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _arrowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B2A4A),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlePainter(_particleController.value),
                  size: size,
                );
              },
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated arrow logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _arrowController,
                      builder: (context, child) {
                        return Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF3B82F6),
                                Color(0xFF1D4ED8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _ArrowLogoPainter(_arrowDraw.value),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App name
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          appConfig.app.name.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'TAP • CLEAR • FLOW',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF93C5FD),
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loading dots
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase = (_particleController.value + i * 0.33) % 1;
                      final opacity = (sin(phase * pi * 2) * 0.5 + 0.5);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3B82F6)
                              .withValues(alpha: opacity),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws animated L-shaped arrow path inside the logo circle.
class _ArrowLogoPainter extends CustomPainter {
  final double progress;
  _ArrowLogoPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const strokeW = 6.0;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // L-shaped arrow path: goes right then up, with arrowhead
    // Tail → corner → head (pointing up)
    final tailX = cx - 22.0;
    final tailY = cy + 14.0;
    final cornerX = cx + 16.0;
    final cornerY = cy + 14.0;
    final headX = cx + 16.0;
    final headY = cy - 18.0;

    // Total path length for progress animation
    const seg1 = 38.0; // horizontal
    const seg2 = 32.0; // vertical
    const totalLen = seg1 + seg2;

    final drawn = progress * totalLen;

    if (drawn <= 0) return;

    final path = Path();
    path.moveTo(tailX, tailY);

    if (drawn <= seg1) {
      path.lineTo(tailX + drawn, tailY);
    } else {
      path.lineTo(cornerX, cornerY);
      final seg2Drawn = drawn - seg1;
      path.lineTo(cornerX, cornerY - seg2Drawn);
    }

    canvas.drawPath(path, paint);

    // Draw arrowhead when near complete
    if (progress > 0.85) {
      final headOpacity = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
      final arrowPaint = Paint()
        ..color = Colors.white.withValues(alpha: headOpacity)
        ..style = PaintingStyle.fill;

      final hs = 10.0;
      final headPath = Path();
      headPath.moveTo(headX, headY - hs);
      headPath.lineTo(headX - hs * 0.7, headY + hs * 0.3);
      headPath.lineTo(headX + hs * 0.7, headY + hs * 0.3);
      headPath.close();
      canvas.drawPath(headPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowLogoPainter old) => old.progress != progress;
}

/// Background floating particles.
class _ParticlePainter extends CustomPainter {
  final double time;
  static final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(
      Random(i * 31 + 7).nextDouble(),
      Random(i * 17 + 3).nextDouble(),
      Random(i * 53 + 11).nextDouble() * 0.4 + 0.1,
      Random(i * 41 + 5).nextDouble() * 0.5 + 0.2,
    ),
  );

  _ParticlePainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = (p.startY + time * p.speed) % 1.0;
      final x = p.startX +
          sin(time * 2 * pi * p.wobble + p.startY * 10) * 0.04;
      final opacity = (sin(time * 2 * pi + p.startY * 5) * 0.3 + 0.2).clamp(0.05, 0.4);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size * 3,
        Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

class _Particle {
  final double startX;
  final double startY;
  final double speed;
  final double size;
  final double wobble;

  _Particle(this.startX, this.startY, this.speed, this.size)
      : wobble = startX * 3 + startY;
}
