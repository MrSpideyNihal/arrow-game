import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../data/repositories/level_repository.dart';
import '../../../main.dart';
import '../../state/gameplay_providers.dart';
import '../profile_me/profile_screen.dart';

/// Root Home screen with 3 bottom nav tabs:
/// 1. Main — Level progression
/// 2. Timer — Timed speed challenge mode
/// 3. Shop — Cosmetic Shop & Customization
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _MainTab(),
      const _TimerModeTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[_currentIndex]),

            // Banner Ad Slot
            AdsService(config: appConfig.ads)
                .buildBannerAdWidget(placement: 'home_screen'),

            // Bottom Navigation Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white10, width: 1),
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: const Color(0xFF0B1120),
                  indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.18),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      );
                    }
                    return const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(color: Color(0xFF3B82F6), size: 24);
                    }
                    return const IconThemeData(color: Colors.white54, size: 24);
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Main',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.timer_outlined),
                      selectedIcon: Icon(Icons.timer_rounded),
                      label: 'Timer',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront_rounded),
                      label: 'Shop',
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
/// Main Tab: Level progression
class _MainTab extends ConsumerStatefulWidget {
  const _MainTab();

  @override
  ConsumerState<_MainTab> createState() => _MainTabState();
}

class _MainTabState extends ConsumerState<_MainTab> {
  late bool _isAudioEnabled;

  @override
  void initState() {
    super.initState();
    final audio = AudioService(config: appConfig.audio);
    _isAudioEnabled = audio.isMusicEnabled || audio.isSfxEnabled;
    if (_isAudioEnabled) {
      audio.playMusic();
    }
  }

  void _toggleAudio() {
    HapticsService().tap();
    final audio = AudioService(config: appConfig.audio);
    final newState = !audio.isMusicEnabled;
    setState(() => _isAudioEnabled = newState);
    audio.toggleMusic(newState);
    audio.toggleSfx(newState);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newState ? 'Sound & Music ON 🔊' : 'Sound & Music MUTED 🔇',
          style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioService(config: appConfig.audio);
    _isAudioEnabled = audio.isMusicEnabled;
    final progress = ref.watch(progressProvider);
    final currentLevel = progress.unlockedLevelId;
    final totalStars = progress.totalStars;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ARROWMINT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'THE ARROW GAME',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF38BDF8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Audio Toggle Button
                  GestureDetector(
                    onTap: _toggleAudio,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _isAudioEnabled
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isAudioEnabled
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Icon(
                        _isAudioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        size: 20,
                        color: _isAudioEnabled ? const Color(0xFF38BDF8) : Colors.white54,
                      ),
                    ),
                  ),

                  // Stars Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE047).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFDE047)),
                        const SizedBox(width: 5),
                        Text(
                          '$totalStars',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFFFDE047),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Hero Level Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  'Level $currentLevel',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap to solve • Unblock all arrows',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFFBFDBFE),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () async {
                    final repo = LevelRepository(config: appConfig.levels);
                    await repo.loadBundledPack();
                    final level = await repo.getLevel(currentLevel);
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamed(AppRouter.gameplay, arguments: level);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'PLAY NOW',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4ED8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Level Map button
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRouter.levelSelect),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Color(0xFF60A5FA), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level Map',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Browse all unlocked puzzle levels',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Timer Mode Tab — speed challenge: clear the board in 45 seconds!
class _TimerModeTab extends StatefulWidget {
  const _TimerModeTab();

  @override
  State<_TimerModeTab> createState() => _TimerModeTabState();
}

class _TimerModeTabState extends State<_TimerModeTab> {
  // Timer durations per difficulty (seconds)
  static const _timerOptions = [
    {'label': 'Lightning', 'seconds': 30, 'color': 0xFFEF4444, 'icon': Icons.bolt_rounded},
    {'label': 'Fast', 'seconds': 45, 'color': 0xFFF59E0B, 'icon': Icons.timer_rounded},
    {'label': 'Steady', 'seconds': 60, 'color': 0xFF34D399, 'icon': Icons.hourglass_bottom_rounded},
  ];

  int _selectedTimerIdx = 1; // default: Fast (45s)

  @override
  Widget build(BuildContext context) {
    final selected = _timerOptions[_selectedTimerIdx];
    final accentColor = Color(selected['color'] as int);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.timer_rounded, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIMER MODE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Race against the clock!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Big hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.25),
                  const Color(0xFF0F172A),
                ],
                radius: 1.5,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Big countdown display
                Text(
                  '${selected['seconds']}s',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${selected['label']} Challenge',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Clear all arrows before time runs out',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 24),

                // Info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      icon: Icons.warning_amber_rounded,
                      label: 'Wrong tap = -3s',
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Speed = Sparks',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Timer selector
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SELECT TIMER',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_timerOptions.length, (i) {
              final opt = _timerOptions[i];
              final color = Color(opt['color'] as int);
              final isSelected = i == _selectedTimerIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTimerIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < _timerOptions.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(opt['icon'] as IconData, color: isSelected ? color : Colors.white38, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          '${opt['seconds']}s',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? color : Colors.white54,
                          ),
                        ),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: isSelected ? color.withValues(alpha: 0.8) : Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // BIG PLAY BUTTON
          GestureDetector(
            onTap: () => _startTimerGame(context, selected['seconds'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  const Text(
                    'START TIMER MODE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Rules card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HOW IT WORKS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                _RuleRow(icon: Icons.touch_app_rounded, color: const Color(0xFF60A5FA), text: 'Tap free arrows (arrows pointing to open space)'),
                _RuleRow(icon: Icons.timer_rounded, color: const Color(0xFF34D399), text: 'Clear all before the timer hits zero'),
                _RuleRow(icon: Icons.close_rounded, color: const Color(0xFFEF4444), text: 'Wrong tap = 3 second penalty!'),
                _RuleRow(icon: Icons.auto_awesome_rounded, color: const Color(0xFFF59E0B), text: 'Faster clear = more Sparks earned'),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _startTimerGame(BuildContext context, int seconds) async {
    final repo = LevelRepository(config: appConfig.levels);
    await repo.loadBundledPack();

    // Select level ID range based on difficulty: Lightning (15-35), Fast (25-50), Steady (40-75)
    List<int> candidateLevelIds;
    if (seconds <= 30) {
      candidateLevelIds = List.generate(20, (i) => 15 + i); // 15..34
    } else if (seconds <= 45) {
      candidateLevelIds = List.generate(25, (i) => 25 + i); // 25..49
    } else {
      candidateLevelIds = List.generate(35, (i) => 40 + i); // 40..74
    }

    final levelId = candidateLevelIds[DateTime.now().millisecond % candidateLevelIds.length];
    final level = await repo.getLevel(levelId);

    if (!context.mounted) return;
    Navigator.of(context).pushNamed(
      AppRouter.gameplay,
      arguments: {'level': level, 'isTimerMode': true, 'timerSeconds': seconds},
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RuleRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
