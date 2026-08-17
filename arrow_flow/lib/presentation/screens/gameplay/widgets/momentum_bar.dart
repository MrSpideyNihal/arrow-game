import 'package:flutter/material.dart';

/// Momentum combo bar displayed at the top of the gameplay board.
///
/// Visualizes the current combo streak and tier. The bar fills as consecutive
/// valid removals land within the combo window. Tiers are shown as segments.
/// Full implementation wired in Phase 4; this provides the visual shell.
class MomentumBar extends StatelessWidget {
  /// Current combo count (number of consecutive hits in the combo window).
  final int comboCount;

  /// Current tier: 0=x1, 1=x2, 2=x3, 3=FLOW STATE.
  final int tier;

  /// Progress within the current tier (0.0 to 1.0).
  final double tierProgress;

  /// Whether the combo timer is actively counting down.
  final bool isActive;

  const MomentumBar({
    super.key,
    this.comboCount = 0,
    this.tier = 0,
    this.tierProgress = 0.0,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    // Tier labels.
    final tierLabels = ['x1', 'x2', 'x3', 'FLOW'];
    final currentLabel = tier < tierLabels.length ? tierLabels[tier] : 'FLOW';

    // Bar opacity increases with tier.
    final barOpacity = isActive ? 1.0 : 0.3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier label (only visible when combo is active).
          AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              currentLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: _tierColor(tier, accentColor),
                fontWeight: FontWeight.w600,
                letterSpacing: tier == 3 ? 2.0 : 0.5,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Progress bar with tier segments.
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 150),
                widthFactor: _overallProgress().clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        _tierColor(tier, accentColor).withValues(alpha: barOpacity),
                        _tierColor(tier, accentColor)
                            .withValues(alpha: barOpacity * 0.7),
                      ],
                    ),
                    boxShadow: isActive && tier >= 2
                        ? [
                            BoxShadow(
                              color: _tierColor(tier, accentColor)
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Maps overall combo progress to a 0-1 range across all tiers.
  double _overallProgress() {
    // Thresholds: 3, 6, 10. Total segments = 4 (x1, x2, x3, FLOW).
    const segments = 4;
    final segmentWidth = 1.0 / segments;
    return (tier * segmentWidth) + (tierProgress * segmentWidth);
  }

  /// Returns a distinct color per tier.
  Color _tierColor(int tier, Color accent) {
    return switch (tier) {
      0 => accent.withValues(alpha: 0.5),
      1 => accent.withValues(alpha: 0.7),
      2 => accent,
      3 => accent, // FLOW STATE: full accent with glow.
      _ => accent,
    };
  }
}

/// A FractionallySizedBox that animates width changes.
class AnimatedFractionallySizedBox extends StatelessWidget {
  final Duration duration;
  final double widthFactor;
  final AlignmentGeometry alignment;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.duration,
    required this.widthFactor,
    required this.alignment,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: child,
      ),
    );
  }
}
