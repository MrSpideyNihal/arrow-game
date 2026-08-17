import 'package:flutter/material.dart';

/// Premium HUD bar adapting dynamically to dark or light themes.
/// Supports Timer Mode with a live countdown arc/bar.
class HudBar extends StatelessWidget {
  final int levelId;
  final int livesRemaining;
  final int livesTotal;
  final int arrowsRemaining;
  final String difficulty;
  final VoidCallback onBackTap;
  final VoidCallback onSettingsTap;
  final VoidCallback? onGridToggle;
  final bool showGrid;
  final bool isDark;
  final bool isTimerMode;
  final int timerSecondsLeft;
  final int timerSecondsTotal;

  const HudBar({
    super.key,
    required this.levelId,
    required this.livesRemaining,
    required this.livesTotal,
    required this.arrowsRemaining,
    required this.difficulty,
    required this.onBackTap,
    required this.onSettingsTap,
    this.onGridToggle,
    this.showGrid = false,
    this.isDark = true,
    this.isTimerMode = false,
    this.timerSecondsLeft = 45,
    this.timerSecondsTotal = 45,
  });

  Color get _diffColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF34D399);
      case 'normal':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case 'hard':
        return const Color(0xFFF59E0B);
      case 'expert':
        return const Color(0xFFEF4444);
      case 'master':
        return const Color(0xFFA855F7);
      case 'boss':
      case 'ultra hard':
        return const Color(0xFFFF0055);
      default:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    }
  }

  Color get _timerColor {
    final pct = timerSecondsLeft / timerSecondsTotal;
    if (pct > 0.5) return const Color(0xFF34D399); // green
    if (pct > 0.25) return const Color(0xFFF59E0B); // orange
    return const Color(0xFFEF4444); // red
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF831843);
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFBE185D).withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: back | level title + timer | settings
          Row(
            children: [
              _IconBtn(
                icon: Icons.arrow_back_ios_rounded,
                onTap: onBackTap,
                color: textColor,
                bgColor: iconBgColor,
              ),
              Expanded(
                child: Center(
                  child: isTimerMode
                      ? _TimerDisplay(
                          secondsLeft: timerSecondsLeft,
                          timerColor: _timerColor,
                          isDark: isDark,
                        )
                      : Text(
                          'Level $levelId',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              if (onGridToggle != null) ...[
                _IconBtn(
                  icon: showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                  onTap: onGridToggle!,
                  color: showGrid ? const Color(0xFF10B981) : textColor,
                  bgColor: iconBgColor,
                ),
                const SizedBox(width: 6),
              ],
              _IconBtn(
                icon: Icons.tune_rounded,
                onTap: onSettingsTap,
                color: textColor,
                bgColor: iconBgColor,
              ),
            ],
          ),

          // Timer progress bar (only in timer mode)
          if (isTimerMode) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (timerSecondsLeft / timerSecondsTotal).clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
                minHeight: 4,
              ),
            ),
          ],

          if (!isTimerMode) ...[
            const SizedBox(height: 6),

            // Sub row: arrows pill | hearts | difficulty pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Arrow count
                _Pill(
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFFDB2777),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF9D174D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$arrowsRemaining',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF9D174D),
                        ),
                      ),
                    ],
                  ),
                ),

                // Heart lives
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(livesTotal, (i) {
                    final filled = i < livesRemaining;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20,
                        color: filled
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    );
                  }),
                ),

                // Difficulty badge
                _Pill(
                  color: _diffColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (difficulty.toUpperCase() == 'BOSS') ...[
                        const Text('🔥', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        difficulty.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _diffColor,
                          letterSpacing: 1,
                        ),
                      ),
                      if (difficulty.toUpperCase() == 'BOSS') ...[
                        const SizedBox(width: 3),
                        const Text('🔥', style: TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            // In timer mode: show arrows remaining inline
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  '$arrowsRemaining arrows left',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Animated timer display for timer mode.
class _TimerDisplay extends StatelessWidget {
  final int secondsLeft;
  final Color timerColor;
  final bool isDark;

  const _TimerDisplay({
    required this.secondsLeft,
    required this.timerColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsLeft <= 10;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_rounded,
          size: 18,
          color: timerColor,
        ),
        const SizedBox(width: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: isUrgent ? 1.15 : 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Text(
            secondsLeft.toString(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isUrgent ? 24 : 22,
              fontWeight: FontWeight.w900,
              color: timerColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Text(
          's',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: timerColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.bgColor = Colors.white10,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Pill({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }
}
