import 'package:flutter/material.dart';

/// Premium animated Momentum Bar & Dynamic Combo Multiplier visualizer.
///
/// Shows live combo multiplier tiers, streak counts, time-window countdown,
/// and glowing "FLOW STATE" activation effects.
class MomentumBar extends StatelessWidget {
  /// Current combo count (number of consecutive hits in the combo window).
  final int comboCount;

  /// Current tier: 0=x1, 1=x2, 2=x3, 3=FLOW STATE.
  final int tier;

  /// Progress within the current tier (0.0 to 1.0).
  final double tierProgress;

  /// Whether the combo timer is actively counting down.
  final bool isActive;

  /// Whether the theme is dark.
  final bool isDark;

  const MomentumBar({
    super.key,
    this.comboCount = 0,
    this.tier = 0,
    this.tierProgress = 0.0,
    this.isActive = false,
    this.isDark = true,
  });

  Color _tierColor(int tier) {
    return switch (tier) {
      0 => const Color(0xFF34D399), // Mint Green (x1)
      1 => const Color(0xFF38BDF8), // Cyan Blue (x2)
      2 => const Color(0xFFF59E0B), // Golden Flame (x3)
      3 => const Color(0xFFA855F7), // Cosmic Purple (FLOW STATE)
      _ => const Color(0xFF38BDF8),
    };
  }

  String _tierBadgeText() {
    if (tier >= 3) return '🔥 FLOW STATE ACTIVE! 🔥';
    if (tier == 2) return '⚡ 3X MULTIPLIER ⚡';
    if (tier == 1) return '✨ 2X STREAK ✨';
    return '$comboCount STREAK';
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);
    final isFlow = tier >= 3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive && comboCount >= 2
            ? color.withValues(alpha: isDark ? 0.15 : 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive && comboCount >= 2
              ? color.withValues(alpha: isFlow ? 0.6 : 0.3)
              : Colors.transparent,
          width: isFlow ? 1.5 : 1.0,
        ),
        boxShadow: isActive && isFlow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Multiplier & Streak Header (visible when combo >= 2)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isActive && comboCount >= 2
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 2),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Streak counter
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFlow ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
                        size: 15,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$comboCount HITS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Center: Multiplier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _tierBadgeText(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Right: Bonus hint
                  Text(
                    isFlow ? '+300% Sparks' : (tier == 2 ? '+200%' : '+100%'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4-Tier Segmented Momentum Bar
          Row(
            children: List.generate(4, (index) {
              final segmentFilled = index < tier || (index == tier && tierProgress > 0);
              final segmentProgress = index < tier
                  ? 1.0
                  : (index == tier ? tierProgress : 0.0);
              final segColor = _tierColor(index);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 4.0 : 0.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: isFlow ? 5 : 4,
                      color: isDark ? Colors.white10 : Colors.black12,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: segmentProgress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                segColor,
                                segColor.withValues(alpha: 0.8),
                              ],
                            ),
                            boxShadow: segmentFilled && (index >= 2 || isFlow)
                                ? [
                                    BoxShadow(
                                      color: segColor.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
