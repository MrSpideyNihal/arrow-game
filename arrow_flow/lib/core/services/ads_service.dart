import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../../data/models/arrow_model.dart';

/// Config-driven Ads Service communicating with native Google Play Services AdMob on Android
/// and interactive simulated player on Web/offline fallback.
class AdsService {
  final AdsConfig config;
  final bool isRemoveAdsPurchased;

  AdsService({
    required this.config,
    this.isRemoveAdsPurchased = false,
  });

  static const MethodChannel _channel = MethodChannel('com.arrowmint.thearrowgame/ads');
  static bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Google Mobile Ads SDK on native platforms.
  Future<void> initialize() async {
    if (!config.enableAds || isRemoveAdsPurchased) return;
    if (!kIsWeb && !_isInitialized) {
      try {
        await _channel.invokeMethod('initAds');
        _isInitialized = true;
      } catch (e) {
        debugPrint('Google Mobile Ads native initialization: $e');
      }
    }
  }

  /// Builds a responsive visual Banner Ad widget.
  Widget buildBannerAdWidget({required String placement}) {
    if (!config.enableAds || isRemoveAdsPurchased) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'AD',
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Google AdMob • Sponsored',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Unlock premium skins and hints!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'INSTALL',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays real Google AdMob Rewarded Video Ad on Android with fallback.
  Future<bool> showRewardedAd({
    required String trigger,
    required VoidCallback onUserEarnedReward,
    BuildContext? context,
  }) async {
    if (!config.enableAds || isRemoveAdsPurchased) {
      onUserEarnedReward();
      return true;
    }

    if (!kIsWeb) {
      try {
        final result = await _channel.invokeMethod<bool>(
          'showRewardedAd',
          {'adUnitId': config.rewardedAdUnitId},
        );
        if (result == true) {
          onUserEarnedReward();
          return true;
        }
      } catch (e) {
        debugPrint('AdMob Native RewardedAd fallback triggered: $e');
      }
    }

    // Interactive fallback if ad is loading or dismissed
    return _showFallbackAd(context, trigger, onUserEarnedReward);
  }

  Future<bool> _showFallbackAd(
    BuildContext? context,
    String trigger,
    VoidCallback onUserEarnedReward,
  ) async {
    if (context != null && context.mounted) {
      final rewarded = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black,
        pageBuilder: (ctx, anim1, anim2) => _FullScreenRewardedAd(trigger: trigger),
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (ctx, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      );

      if (rewarded == true) {
        onUserEarnedReward();
        return true;
      }
      return false;
    }

    onUserEarnedReward();
    return true;
  }
}

/// Authentic Full-Screen Rewarded Video Ad with countdown, playable teaser, and AdMob end-card.
class _FullScreenRewardedAd extends StatefulWidget {
  final String trigger;

  const _FullScreenRewardedAd({required this.trigger});

  @override
  State<_FullScreenRewardedAd> createState() => _FullScreenRewardedAdState();
}

class _FullScreenRewardedAdState extends State<_FullScreenRewardedAd>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 15;
  static const int _totalAdDuration = 15;
  static const int _skipAllowedAfter = 5;
  Timer? _timer;
  bool _rewardGranted = false;
  bool _isMuted = false;
  bool _showEndCard = false;
  int _playableScore = 1250;
  final List<Offset> _tapParticles = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
          _playableScore += 250;
        });
      } else {
        setState(() {
          _secondsRemaining = 0;
          _rewardGranted = true;
          _showEndCard = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapAdCanvas(TapDownDetails details) {
    if (_showEndCard) return;
    setState(() {
      _playableScore += 500;
      _tapParticles.add(details.localPosition);
      if (_tapParticles.length > 8) _tapParticles.removeAt(0);
    });
  }

  Future<void> _handleEarlyClose() async {
    if (_rewardGranted || _secondsRemaining <= 0) {
      Navigator.of(context).pop(true);
      return;
    }

    // Show authentic AdMob "Leave Ad?" warning dialog
    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Leave Ad Early?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'If you close now, you will NOT receive your reward! You can skip in ${_secondsRemaining > _skipAllowedAfter ? _secondsRemaining - _skipAllowedAfter : 0}s.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'RESUME AD',
              style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'LEAVE ANYWAY',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalAdDuration - _secondsRemaining) / _totalAdDuration.toDouble();
    final canSkip = (_totalAdDuration - _secondsRemaining) >= _skipAllowedAfter;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Ad Container
            Column(
              children: [
                // Top Authentic AdMob Header
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    children: [
                      // AdMob Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ad',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Google AdMob',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),

                      // Audio Mute Toggle
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isMuted = !_isMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),

                      // Countdown / Skip Button
                      if (_rewardGranted || _secondsRemaining == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Reward Earned',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (canSkip)
                        GestureDetector(
                          onTap: _handleEarlyClose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF475569)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Skip in ${_secondsRemaining}s',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Reward in ${_secondsRemaining}s',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Close 'X' Button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        onPressed: _handleEarlyClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Top Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _rewardGranted ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                  ),
                  minHeight: 3,
                ),

                // Interactive Video & Playable Showcase Area
                Expanded(
                  child: _showEndCard ? _buildEndCard() : _buildPlayableVideoDemo(),
                ),

                // Bottom Call To Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Row(
                    children: [
                      // App Icon
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Arrow Master: Labyrinth 3D',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: const [
                                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                SizedBox(width: 2),
                                Text(
                                  '4.9 ★ • 50M+ Downloads',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Action Button
                      ElevatedButton(
                        onPressed: () {
                          if (_rewardGranted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rewardGranted ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                        ),
                        child: Text(
                          _rewardGranted ? 'CLAIM REWARD ✓' : 'INSTALL NOW',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Playable Video Area with Interactive gameplay demo
  Widget _buildPlayableVideoDemo() {
    return GestureDetector(
      onTapDown: _onTapAdCanvas,
      child: Container(
        width: double.infinity,
        color: const Color(0xFF050510),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background grid visual
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(
                  painter: _AdGridPainter(),
                ),
              ),
            ),

            // Animated Gameplay Trailer Graphics
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Score banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF6366F1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'COMBO SCORE: $_playableScore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Animated Playable Arrows Showcase
                Container(
                  width: 280,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Arrow demo paths
                      Positioned(
                        top: 30,
                        left: 40,
                        child: _buildPlayableArrow(Direction.right, const Color(0xFF38BDF8)),
                      ),
                      Positioned(
                        top: 70,
                        right: 40,
                        child: _buildPlayableArrow(Direction.left, const Color(0xFFF472B6)),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 80,
                        child: _buildPlayableArrow(Direction.up, const Color(0xFF34D399)),
                      ),

                      // Interactive "TAP TO PLAY" Finger Badge
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.touch_app_rounded, color: Colors.black, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'TAP TO PLAY DEMO!',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Live status text
                Text(
                  'Sponsored Ad • Playing Video Preview (${_secondsRemaining}s left)',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Tap Particle Sparks
            ..._tapParticles.map(
              (pos) => Positioned(
                left: pos.dx - 20,
                top: pos.dy - 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (ctx, val, child) => Opacity(
                    opacity: val,
                    child: Transform.scale(
                      scale: 1.0 + (1.0 - val),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFFFDE047), size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayableArrow(Direction dir, Color color) {
    final IconData icon;
    switch (dir) {
      case Direction.up:
        icon = Icons.arrow_upward_rounded;
        break;
      case Direction.down:
        icon = Icons.arrow_downward_rounded;
        break;
      case Direction.left:
        icon = Icons.arrow_back_rounded;
        break;
      case Direction.right:
        icon = Icons.arrow_forward_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  /// Authentic AdMob End Card
  Widget _buildEndCard() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing App Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 18),

          const Text(
            'Arrow Master 3D',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The #1 Trending Labyrinth Puzzle Game',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Rating Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
            ),
          ),
          const SizedBox(height: 24),

          // Success Reward Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'REWARD UNLOCKED & READY!',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Primary Return Button
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
                child: const Text(
                  'CLAIM REWARD & RESUME GAME',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.0;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

