import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../main.dart';
import '../../../l10n/app_strings.dart';

/// Premium main menu with gradient background and animated arrow decorations.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _enterController;
  late AnimationController _floatController;
  late AnimationController _bgController;

  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _enterController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _enterController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _enterController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _floatController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF0D1B2A), const Color(0xFF1A0E2E),
                      _bgController.value)!,
                  Color.lerp(const Color(0xFF1B2A4A), const Color(0xFF2A1B3D),
                      _bgController.value)!,
                  Color.lerp(const Color(0xFF0D1B2A), const Color(0xFF0E1A2A),
                      _bgController.value)!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Decorative background arrows
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BgArrowsPainter(_floatController.value),
                  size: size,
                );
              },
            ),

            // Glow orb top right
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      const Color(0xFF3B82F6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Glow orb bottom left
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Title section
                    AnimatedBuilder(
                      animation: _enterController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _titleSlide.value),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          // Logo
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0,
                                    sin(_floatController.value * pi) * 8),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF60A5FA),
                                    Color(0xFF2563EB),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // App name
                          Text(
                            appConfig.app.name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap. Clear. Flow.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Menu buttons
                    AnimatedBuilder(
                      animation: _enterController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _btnFade.value,
                          child: child,
                        );
                      },
                      child: Column(
                        children: [
                          _PremiumButton(
                            label: AppStrings.play,
                            icon: Icons.play_arrow_rounded,
                            isPrimary: true,
                            onTap: () {
                              AudioService(config: appConfig.audio).onFirstInteraction();
                              Navigator.of(context).pushNamed(AppRouter.levelSelect);
                            },
                          ),
                          const SizedBox(height: 12),
                          if (appConfig.featureFlags.dailyChallenge) ...[
                            _PremiumButton(
                              label: AppStrings.dailyChallenge,
                              icon: Icons.calendar_today_rounded,
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRouter.dailyChallenge),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _PremiumButton(
                            label: 'Cosmetic Shop',
                            icon: Icons.storefront_rounded,
                            onTap: () =>
                                Navigator.of(context).pushNamed(AppRouter.profile),
                          ),
                          const SizedBox(height: 12),
                          _PremiumButton(
                            label: AppStrings.settings,
                            icon: Icons.tune_rounded,
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRouter.settings),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Banner Ad slot
                    AdsService(config: appConfig.ads)
                        .buildBannerAdWidget(placement: 'main_menu'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium menu button with glassmorphism styling.
class _PremiumButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: child);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  )
                : null,
            color: widget.isPrimary
                ? null
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isPrimary
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Background decorative arrows that float gently.
class _BgArrowsPainter extends CustomPainter {
  final double t;

  _BgArrowsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final arrows = [
      (0.08, 0.15, 0.0),
      (0.85, 0.22, 1.2),
      (0.15, 0.6, 2.1),
      (0.78, 0.55, 0.8),
      (0.45, 0.88, 1.5),
      (0.92, 0.78, 2.7),
      (0.05, 0.85, 0.3),
    ];

    for (final (bx, by, phase) in arrows) {
      final yOff = sin(t * pi + phase) * 10;
      final opacity = (sin(t * pi * 0.5 + phase) * 0.05 + 0.06)
          .clamp(0.02, 0.12);
      _drawDecorArrow(
        canvas,
        Offset(bx * size.width, by * size.height + yOff),
        opacity,
        (phase * 45) % 360,
      );
    }
  }

  void _drawDecorArrow(Canvas canvas, Offset center, double opacity, double angleDeg) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * pi / 180);

    // Simple arrow shape
    final path = Path();
    path.moveTo(-20, 8);
    path.lineTo(0, 8);
    path.lineTo(0, -8);
    canvas.drawPath(path, paint);

    // Arrowhead
    final headPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final head = Path();
    head.moveTo(0, -14);
    head.lineTo(-7, -5);
    head.lineTo(7, -5);
    head.close();
    canvas.drawPath(head, headPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BgArrowsPainter old) => true;
}
