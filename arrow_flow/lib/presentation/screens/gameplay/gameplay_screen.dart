import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/arrow_model.dart';
import '../../../data/models/level_model.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/economy_model.dart';
import '../../../main.dart';
import '../../state/gameplay_providers.dart';
import 'widgets/board_view.dart';
import 'widgets/hud_bar.dart';
import 'widgets/momentum_bar.dart';

/// Premium gameplay screen. Supports both normal and timer mode.
class GameplayScreen extends ConsumerStatefulWidget {
  final Level level;
  final bool isTimerMode;
  final int timerSeconds;

  const GameplayScreen({
    super.key,
    required this.level,
    this.isTimerMode = false,
    this.timerSeconds = 45,
  });

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen>
    with TickerProviderStateMixin {
  Arrow? _hintedArrow;
  Timer? _comboTimer;
  Timer? _countdownTimer;
  late AnimationController _enterController;
  late Animation<double> _enterFade;

  bool _showGrid = false;
  int _adsWatchedForSkip = 0;
  bool _gameOverShown = false;
  bool _timeUpShown = false;

  String? _comboBannerText;
  Color _comboBannerColor = const Color(0xFF38BDF8);
  Timer? _comboBannerTimer;

  void _triggerComboBanner(String text, Color color) {
    _comboBannerTimer?.cancel();
    setState(() {
      _comboBannerText = text;
      _comboBannerColor = color;
    });
    _comboBannerTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _comboBannerText = null);
      }
    });
  }

  AlwaysAliveRefreshable<GameState> get _stateProvider => widget.isTimerMode
      ? timerGameStateProvider(TimerLevelArgs(level: widget.level, timerSeconds: widget.timerSeconds))
      : gameStateProvider(widget.level);

  bool _isBombMode = false;
  bool _isRadarActive = false;
  Timer? _radarTimer;

  AlwaysAliveRefreshable<GameStateNotifier> get _notifierProvider => widget.isTimerMode
      ? timerGameStateProvider(TimerLevelArgs(level: widget.level, timerSeconds: widget.timerSeconds)).notifier
      : gameStateProvider(widget.level).notifier;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _enterController.forward();

    // Combo window ticker
    _comboTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        ref.read(_notifierProvider).checkComboWindow();
      }
    });

    // Timer mode countdown ticker
    if (widget.isTimerMode) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          ref.read(_notifierProvider).tickTimer();
          final left = ref.read(_stateProvider).timerSecondsLeft;
          if (left <= 10 && left > 0) {
            AudioService(config: appConfig.audio).playTick(isUrgent: true);
          } else if (left > 10) {
            AudioService(config: appConfig.audio).playTick(isUrgent: false);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    _countdownTimer?.cancel();
    _radarTimer?.cancel();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(_stateProvider);

    // Navigate to level complete when all arrows are cleared.
    if (gameState.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _countdownTimer?.cancel();
          _radarTimer?.cancel();
          AudioService(config: appConfig.audio).playLevelComplete();
          Navigator.of(context).pushReplacementNamed(
            AppRouter.levelComplete,
            arguments: {
              'level': widget.level,
              'mistakes': gameState.mistakes,
              'flowStateReached': gameState.comboState.flowStateReached,
              'isTimerMode': widget.isTimerMode,
              'timerSeconds': widget.timerSeconds,
            },
          );
        }
      });
    }

    // Show time's up dialog (timer mode)
    if (gameState.isTimeUp && !_timeUpShown) {
      _timeUpShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showTimeUpDialog(context);
      });
    }

    // Show game over dialog (normal mode only)
    if (gameState.isGameOver && !gameState.isTimeUp && !_gameOverShown) {
      _gameOverShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOverDialog(context);
      });
    }

    final storage = StorageService();
    final themeId = storage.getSetting<String>('active_theme', defaultValue: 'theme_default')!;
    final themeItem = CosmeticItem.catalog.firstWhere(
      (item) => item.id == themeId,
      orElse: () => CosmeticItem.catalog.firstWhere((i) => i.id == 'theme_default'),
    );
    final bgColor = _parseColor(themeItem.backgroundColorHex ?? '#0F172A');
    final isDark = bgColor.computeLuminance() < 0.5;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _enterFade,
        child: SafeArea(
          child: Column(
            children: [
              // Top HUD Bar
              HudBar(
                levelId: widget.level.id,
                livesRemaining: gameState.livesRemaining,
                livesTotal: 3,
                arrowsRemaining: gameState.arrowsRemaining,
                difficulty: gameState.level.difficulty,
                isDark: isDark,
                isTimerMode: widget.isTimerMode,
                timerSecondsLeft: gameState.timerSecondsLeft,
                timerSecondsTotal: gameState.timerSecondsTotal,
                onGridToggle: () => setState(() => _showGrid = !_showGrid),
                showGrid: _showGrid,
                onBackTap: () {
                  _countdownTimer?.cancel();
                  Navigator.of(context).pushReplacementNamed(AppRouter.home);
                },
                onSettingsTap: () => _showPauseSheet(context, isDark),
              ),

              // Live Dynamic Combo & Momentum Multiplier Bar
              MomentumBar(
                comboCount: gameState.comboState.comboCount,
                tier: gameState.comboState.currentTier,
                tierProgress: gameState.comboState.tierProgress,
                isActive: gameState.comboState.comboCount > 0,
                isDark: isDark,
              ),

              // Puzzle Board with Interactive Zoom & Pan & Flow State Aura
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Board with Flow State breathing glow
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: gameState.comboState.currentTier >= 3
                              ? Border.all(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.85),
                                  width: 2.5,
                                )
                              : (gameState.comboState.currentTier >= 2
                                  ? Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                      width: 1.5,
                                    )
                                  : null),
                          boxShadow: gameState.comboState.currentTier >= 3
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : (gameState.comboState.currentTier >= 2
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null),
                        ),
                        child: BoardView(
                          level: widget.level,
                          activeArrows: gameState.activeArrows,
                          selectableArrows: gameState.selectableArrows,
                          hintedArrow: _hintedArrow,
                          onArrowTap: (arrow) => _onArrowTap(arrow),
                          showGrid: _showGrid,
                          isBombMode: _isBombMode,
                          isRadarActive: _isRadarActive,
                        ),
                      ),

                      // Floating Combo Surge Banner Overlay
                      if (_comboBannerText != null)
                        Positioned(
                          top: 12,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.6, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _comboBannerColor.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _comboBannerColor.withValues(alpha: 0.65),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _comboBannerText!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom controls bar (Clean 4-button layout, zero overflow)
              if (!widget.isTimerMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 4, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Hint Booster
                      _ActionButton(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Hint',
                        badgeCount: gameState.hintsRemaining,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () => _onHintTap(gameState),
                      ),

                      // Bomb Booster
                      _ActionButton(
                        icon: Icons.local_fire_department_rounded,
                        label: _isBombMode ? 'Cancel' : 'Bomb',
                        badgeCount: gameState.bombsRemaining,
                        color: _isBombMode ? const Color(0xFFDC2626) : const Color(0xFFEF4444),
                        isDark: isDark,
                        onTap: () => _onBombTap(gameState),
                      ),

                      // Radar Scanner Booster
                      _ActionButton(
                        icon: Icons.radar_rounded,
                        label: 'Radar',
                        badgeCount: gameState.radarsRemaining,
                        color: const Color(0xFF06B6D4),
                        isDark: isDark,
                        onTap: () => _onRadarTap(gameState),
                      ),

                      // Reset Level
                      _ActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Reset',
                        badgeCount: 0,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        isDark: isDark,
                        onTap: () {
                          HapticsService().tap();
                          setState(() {
                            _gameOverShown = false;
                            _isBombMode = false;
                            _isRadarActive = false;
                          });
                          ref.read(_notifierProvider).reset();
                        },
                      ),
                    ],
                  ),
                )
              else
                // Timer mode: restart button at bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 6),
                  child: TextButton.icon(
                    onPressed: () {
                      HapticsService().tap();
                      setState(() {
                        _timeUpShown = false;
                        _gameOverShown = false;
                      });
                      _countdownTimer?.cancel();
                      ref.read(_notifierProvider).reset();
                      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                        if (mounted) {
                          ref.read(_notifierProvider).tickTimer();
                          final left = ref.read(_stateProvider).timerSecondsLeft;
                          if (left <= 10 && left > 0) {
                            AudioService(config: appConfig.audio).playTick(isUrgent: true);
                          } else if (left > 10) {
                            AudioService(config: appConfig.audio).playTick(isUrgent: false);
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 18),
                    label: const Text(
                      'Restart',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onArrowTap(Arrow arrow) {
    final notifier = ref.read(_notifierProvider);
    final audio = AudioService(config: appConfig.audio);
    final haptics = HapticsService();

    if (_isBombMode) {
      final blastSuccess = notifier.blastArrow(arrow);
      if (blastSuccess) {
        audio.playBombBlast();
        haptics.comboTier();
      }
      setState(() => _isBombMode = false);
      return;
    }

    final previousTier = ref.read(_stateProvider).comboState.currentTier;
    final comboCount = ref.read(_stateProvider).comboState.comboCount;
    final success = notifier.tapArrow(arrow);
    final currentTier = ref.read(_stateProvider).comboState.currentTier;

    if (success) {
      audio.playRemove(comboCount: comboCount + 1);
      if (currentTier > previousTier) {
        audio.playComboTier();
        haptics.comboTier();
        if (currentTier >= 3) {
          _triggerComboBanner('🔥 FLOW STATE ACTIVE! 🔥', const Color(0xFFA855F7));
        } else if (currentTier == 2) {
          _triggerComboBanner('⚡ 3X MULTIPLIER! ⚡', const Color(0xFFF59E0B));
        } else if (currentTier == 1) {
          _triggerComboBanner('✨ 2X STREAK! ✨', const Color(0xFF38BDF8));
        }
      } else {
        haptics.remove();
      }
    } else {
      audio.playTap();
      haptics.tap();
    }

    if (_hintedArrow != null) {
      setState(() => _hintedArrow = null);
    }
  }

  void _onBombTap(GameState gameState) {
    if (gameState.bombsRemaining <= 0) {
      _showBoosterRefillDialog(
        context: context,
        boosterKey: StorageService.boosterBombs,
        title: 'Need More Bombs?',
        description: 'Vaporize ANY blocked arrow instantly!',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
        packCost: 30,
        packAmount: 3,
      );
      return;
    }
    HapticsService().tap();
    setState(() => _isBombMode = !_isBombMode);
  }

  void _onHintTap(GameState gameState) {
    if (gameState.hintsRemaining <= 0) {
      _showBoosterRefillDialog(
        context: context,
        boosterKey: StorageService.boosterHints,
        title: 'Need More Hints?',
        description: 'Highlights a free playable arrow!',
        icon: Icons.lightbulb_outline_rounded,
        color: const Color(0xFFF59E0B),
        packCost: 20,
        packAmount: 3,
      );
      return;
    }

    final notifier = ref.read(_notifierProvider);
    final hinted = notifier.useHint();

    HapticsService().tap();
    AudioService(config: appConfig.audio).playTap();

    if (hinted != null) {
      setState(() => _hintedArrow = hinted);
    }
  }

  void _onRadarTap(GameState gameState) {
    if (gameState.radarsRemaining <= 0) {
      _showBoosterRefillDialog(
        context: context,
        boosterKey: StorageService.boosterRadars,
        title: 'Need More Radars?',
        description: 'Sweeps & illuminates all free arrows for 3.5s!',
        icon: Icons.radar_rounded,
        color: const Color(0xFF06B6D4),
        packCost: 50,
        packAmount: 3,
      );
      return;
    }

    final success = ref.read(_notifierProvider).useRadar();
    if (success) {
      AudioService(config: appConfig.audio).playRadarSweep();
      HapticsService().tap();
      _radarTimer?.cancel();
      setState(() => _isRadarActive = true);
      _radarTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() => _isRadarActive = false);
        }
      });
    }
  }

  void _showBoosterRefillDialog({
    required BuildContext context,
    required String boosterKey,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int packCost,
    required int packAmount,
  }) {
    HapticsService().tap();
    final storage = StorageService();
    final sparks = storage.getSparksBalance();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),

              // Option 1: Buy with Sparks
              GestureDetector(
                onTap: () async {
                  if (sparks < packCost) {
                    Navigator.of(dialogCtx).pop();
                    _showNoPowerupSnackbar('Not enough Sparks! (Need $packCost, you have $sparks)');
                    return;
                  }
                  await storage.saveSparksBalance(sparks - packCost);
                  ref.read(_notifierProvider).addBooster(boosterKey, packAmount);
                  AudioService(config: appConfig.audio).playComboTier();
                  HapticsService().comboTier();
                  Navigator.of(dialogCtx).pop();
                  _showNoPowerupSnackbar('+$packAmount added to inventory! ✨');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Buy +$packAmount Pack',
                        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$packCost Sparks',
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Option 2: Watch Ad for Free +1
              GestureDetector(
                onTap: () async {
                  Navigator.of(dialogCtx).pop();
                  final adsService = AdsService(config: appConfig.ads);
                  await adsService.showRewardedAd(
                    context: context,
                    trigger: 'booster_refill',
                    onUserEarnedReward: () {
                      ref.read(_notifierProvider).addBooster(boosterKey, 1);
                      AudioService(config: appConfig.audio).playComboTier();
                      HapticsService().comboTier();
                      _showNoPowerupSnackbar('+1 added to inventory! ✨');
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: Color(0xFF34D399), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Watch Video for +1 Free',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoPowerupSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  void _showTimeUpDialog(BuildContext context) {
    _countdownTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E2D45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFFEF4444), width: 2),
                ),
                child: const Icon(
                  Icons.timer_off_rounded,
                  size: 36,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "TIME'S UP!",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You ran out of time!\nBe faster next round.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // +10 Seconds (Watch Ad)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.timer_rounded, color: Colors.white),
                  label: const Text(
                    '+10 SECONDS (WATCH AD)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  onPressed: () async {
                    final adsService = AdsService(config: appConfig.ads);
                    await adsService.showRewardedAd(
                      context: ctx,
                      trigger: 'timer_extra_time',
                      onUserEarnedReward: () {
                        ref.read(_notifierProvider).addTimerSeconds(10);
                      },
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    setState(() {
                      _timeUpShown = false;
                      _gameOverShown = false;
                    });
                    // Resume countdown
                    _countdownTimer?.cancel();
                    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                      if (mounted) {
                        ref.read(_notifierProvider).tickTimer();
                        final left = ref.read(_stateProvider).timerSecondsLeft;
                        if (left <= 10 && left > 0) {
                          AudioService(config: appConfig.audio).playTick(isUrgent: true);
                        } else if (left > 10) {
                          AudioService(config: appConfig.audio).playTick(isUrgent: false);
                        }
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Skip Level (Watch 5 Ads)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA855F7),
                    side: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFA855F7)),
                  label: const Text(
                    'SKIP LEVEL (WATCH 5 ADS)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showSkipLevelDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Try Again
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  label: const Text(
                    'RESTART LEVEL',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _timeUpShown = false;
                      _gameOverShown = false;
                    });
                    ref.read(_notifierProvider).reset();
                    // Restart countdown
                    _countdownTimer?.cancel();
                    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                      if (mounted) {
                        ref.read(_notifierProvider).tickTimer();
                        final left = ref.read(_stateProvider).timerSecondsLeft;
                        if (left <= 10 && left > 0) {
                          AudioService(config: appConfig.audio).playTick(isUrgent: true);
                        } else if (left > 10) {
                          AudioService(config: appConfig.audio).playTick(isUrgent: false);
                        }
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Back to home
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacementNamed(AppRouter.home);
                },
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E2D45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.heart_broken_rounded,
                  size: 32,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'OUT OF LIVES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Watch a video to get +1 Life and keep playing, or restart fresh!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),

              // 1. Watch Ad for +1 Life
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                  label: const Text(
                    'WATCH AD (+1 LIFE)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final adsService = AdsService(config: appConfig.ads);
                    await adsService.showRewardedAd(
                      context: context,
                      trigger: 'revive_life',
                      onUserEarnedReward: () {
                        setState(() => _gameOverShown = false);
                        ref.read(_notifierProvider).revive();
                        _showNoPowerupSnackbar('+1 Life restored! ❤️');
                      },
                    );
                    if (mounted && ref.read(_stateProvider).livesRemaining <= 0) {
                      setState(() => _gameOverShown = false);
                      _showGameOverDialog(context);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),

              // 2. Retry Level
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.replay_rounded, color: Colors.white),
                  label: const Text(
                    'RETRY LEVEL',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() => _gameOverShown = false);
                    ref.read(_notifierProvider).reset();
                  },
                ),
              ),
              const SizedBox(height: 10),

              // 3. Skip Level (5 Ads)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA855F7),
                    side: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFA855F7)),
                  label: const Text(
                    'SKIP LEVEL (WATCH 5 ADS)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showSkipLevelDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // 4. Quit to Menu
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _gameOverShown = false);
                  Navigator.of(context).pushReplacementNamed(AppRouter.levelSelect);
                },
                child: const Text(
                  'Quit Level',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSkipLevelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF1E2D45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.skip_next_rounded,
                      size: 36,
                      color: Color(0xFFA855F7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Skip Level',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Watch 5 short video ads to skip this level instantly!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Progress tracker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.ondemand_video_rounded,
                            color: Color(0xFFA855F7), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Ad Progress: $_adsWatchedForSkip / 5 Watched',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (mounted && ref.read(_stateProvider).livesRemaining <= 0) {
                            setState(() => _gameOverShown = false);
                            _showGameOverDialog(context);
                          }
                        },
                        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA855F7),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                        label: Text(
                          'WATCH AD (${_adsWatchedForSkip + 1}/5)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          final adsService = AdsService(config: appConfig.ads);
                          await adsService.showRewardedAd(
                            context: ctx,
                            trigger: 'skip_level',
                            onUserEarnedReward: () {
                              setDialogState(() {
                                _adsWatchedForSkip++;
                              });
                              setState(() {});
                            },
                          );

                          if (_adsWatchedForSkip >= 5) {
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            HapticsService().comboTier();
                            AudioService(config: appConfig.audio).playLevelComplete();

                            ref
                                .read(progressProvider.notifier)
                                .completeLevel(widget.level.id, 0);

                            if (context.mounted) {
                              Navigator.of(context).pushReplacementNamed(
                                AppRouter.levelComplete,
                                arguments: {
                                  'level': widget.level,
                                  'mistakes': 0,
                                  'flowStateReached': false,
                                  'isTimerMode': widget.isTimerMode,
                                  'timerSeconds': widget.timerSeconds,
                                },
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPauseSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2D45) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'GAME PAUSED',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Skip Level (Watch 5 Ads)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                label: const Text(
                  'SKIP LEVEL (WATCH 5 ADS)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showSkipLevelDialog(context);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Restart Level
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : Colors.black87),
                label: Text(
                  'Restart Level',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(_notifierProvider).reset();
                },
              ),
            ),
            const SizedBox(height: 12),

            // Audio & Settings
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(Icons.settings_rounded, color: isDark ? Colors.white70 : Colors.black87),
                label: Text(
                  'Audio & Settings',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamed(AppRouter.settings);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Circular floating action button with label and badge.
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.color,
    this.isDark = true,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.15),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 26,
                    color: widget.color,
                  ),
                ),
                if (widget.badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.badgeCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF831843),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('FF');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
