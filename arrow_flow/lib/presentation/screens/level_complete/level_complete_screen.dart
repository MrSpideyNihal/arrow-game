import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_repository.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../main.dart';
import '../../state/gameplay_providers.dart';

/// Premium dark-themed level complete screen with celebration effects.
class LevelCompleteScreen extends ConsumerStatefulWidget {
  final Level level;
  final int mistakes;
  final bool flowStateReached;
  final bool isTimerMode;
  final int timerSeconds;

  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.mistakes,
    required this.flowStateReached,
    this.isTimerMode = false,
    this.timerSeconds = 45,
  });

  @override
  ConsumerState<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends ConsumerState<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _confettiController;
  late AnimationController _starController;

  late Animation<double> _contentSlide;
  late Animation<double> _contentFade;
  late Animation<double> _starScale;

  bool _isLoadingNext = false;

  @override
  void initState() {
    super.initState();

    // Play level complete fanfare sound
    AudioService(config: appConfig.audio).playLevelComplete();

    // Save level progress to Hive local storage and award Sparks (30 for 3 stars, 20 for 2, 10 for 1 + Boss bonus)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        ref.read(progressProvider.notifier).completeLevel(widget.level.id, widget.mistakes);
        final storage = StorageService();
        final current = storage.getSparksBalance();
        await storage.saveSparksBalance(current + _sparksEarned);
      }
    });

    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _starController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _contentSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _starScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _starController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    _confettiController.dispose();
    _starController.dispose();
    super.dispose();
  }

  int get _stars => (3 - widget.mistakes).clamp(1, 3);

  int get _sparksEarned {
    int base = 10;
    if (_stars == 3) {
      base = 30;
    } else if (_stars == 2) {
      base = 20;
    }
    // +20 Sparks Boss Level bonus
    if (widget.level.id % 5 == 0) {
      base += 20;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF0D1B2A), const Color(0xFF1A0E2E),
                          _bgController.value)!,
                      Color.lerp(const Color(0xFF1B2A4A), const Color(0xFF0E2A1A),
                          _bgController.value)!,
                      Color.lerp(const Color(0xFF0D1B2A), const Color(0xFF2A1B0E),
                          _bgController.value)!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Glowing orbs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFDE047).withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF34D399).withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Confetti particles
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(_confettiController.value),
                  );
                },
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Opacity(
                  opacity: _contentFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _contentSlide.value),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Trophy icon with glow
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [
                          Color(0xFFFDE047),
                          Color(0xFFF59E0B),
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFDE047).withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'LEVEL CLEAR!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Puzzle #${widget.level.id} Solved',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Stars card
                    AnimatedBuilder(
                      animation: _starController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _starScale.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Stars row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final filled = i < _stars;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: TweenAnimationBuilder<double>(
                                    duration: Duration(
                                        milliseconds: 300 + i * 150),
                                    tween: Tween(begin: 0.0, end: filled ? 1.0 : 0.3),
                                    curve: Curves.elasticOut,
                                    builder: (context, v, _) {
                                      return Transform.scale(
                                        scale: v,
                                        child: Icon(
                                          filled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 52,
                                          color: filled
                                              ? const Color(0xFFFDE047)
                                              : Colors.white
                                                  .withValues(alpha: 0.2),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 20),

                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatChip(
                                  label: 'Stars',
                                  value: '$_stars / 3',
                                  color: const Color(0xFFFDE047),
                                  icon: Icons.star_rounded,
                                ),
                                Container(
                                  height: 36,
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                _StatChip(
                                  label: 'Mistakes',
                                  value: '${widget.mistakes}',
                                  color: widget.mistakes == 0
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFEF4444),
                                  icon: widget.mistakes == 0
                                      ? Icons.check_circle_rounded
                                      : Icons.close_rounded,
                                ),
                                Container(
                                  height: 36,
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                _StatChip(
                                  label: 'Level',
                                  value: '#${widget.level.id}',
                                  color: const Color(0xFF60A5FA),
                                  icon: Icons.grid_view_rounded,
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Sparks Earned Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flash_on_rounded,
                                      size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+$_sparksEarned SPARKS EARNED!',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF59E0B),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (widget.mistakes == 0) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34D399)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF34D399)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 14, color: Color(0xFF34D399)),
                                    SizedBox(width: 6),
                                    Text(
                                      'PERFECT CLEAR!',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34D399),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // NEXT LEVEL button
                    _isLoadingNext
                        ? const CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                          )
                        : _PremiumCTAButton(
                            label: 'NEXT LEVEL',
                            icon: Icons.arrow_forward_rounded,
                            onTap: _goToNextLevel,
                          ),

                    const SizedBox(height: 12),

                    // Secondary buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            label: 'Replay',
                            icon: Icons.refresh_rounded,
                            onTap: _replayLevel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SecondaryButton(
                            label: 'Menu',
                            icon: Icons.home_rounded,
                            onTap: () => Navigator.of(context)
                                .pushReplacementNamed(AppRouter.mainMenu),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToNextLevel() async {
    if (_isLoadingNext) return;
    setState(() => _isLoadingNext = true);

    final nextLevelId = widget.level.id + 1;
    final totalLevels = appConfig.levels.bundledCount;

    // If we've completed all levels, go back to level select
    if (nextLevelId > totalLevels) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.levelSelect);
      }
      return;
    }

    try {
      final repo = LevelRepository(config: appConfig.levels);
      await repo.loadBundledPack();
      final nextLevel = await repo.getLevel(nextLevelId);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.gameplay,
          arguments: {
            'level': nextLevel,
            'isTimerMode': widget.isTimerMode,
            'timerSeconds': widget.timerSeconds,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNext = false);
      }
    }
  }

  Future<void> _replayLevel() async {
    if (_isLoadingNext) return;
    setState(() => _isLoadingNext = true);

    try {
      final repo = LevelRepository(config: appConfig.levels);
      await repo.loadBundledPack();
      final level = await repo.getLevel(widget.level.id);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.gameplay,
          arguments: {
            'level': level,
            'isTimerMode': widget.isTimerMode,
            'timerSeconds': widget.timerSeconds,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNext = false);
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _PremiumCTAButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumCTAButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PremiumCTAButton> createState() => _PremiumCTAButtonState();
}

class _PremiumCTAButtonState extends State<_PremiumCTAButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        duration: const Duration(milliseconds: 80), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Icon(widget.icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colorful confetti burst painter.
class _ConfettiPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _particles = List.generate(
    60,
    (i) => _CP(
      _rng.nextDouble(),
      _rng.nextDouble() * -0.3,
      _rng.nextDouble() * 0.4 + 0.2,
      _rng.nextDouble() * 10 + 5,
      [
        const Color(0xFFFDE047),
        const Color(0xFF60A5FA),
        const Color(0xFFF87171),
        const Color(0xFF34D399),
        const Color(0xFFA78BFA),
        const Color(0xFFFB923C),
      ][i % 6],
      _rng.nextDouble() * 2 * pi,
    ),
  );

  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _particles) {
      final yt = (p.y + t * p.speed) % 1.3;
      final xt = p.x + sin(t * 2 * pi * 0.7 + p.rot) * 0.04;
      paint.color = p.color;
      canvas.save();
      canvas.translate(xt * size.width, yt * size.height);
      canvas.rotate(t * 4 * pi + p.rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}

class _CP {
  final double x, y, speed, size, rot;
  final Color color;
  _CP(this.x, this.y, this.speed, this.size, this.color, this.rot);
}
