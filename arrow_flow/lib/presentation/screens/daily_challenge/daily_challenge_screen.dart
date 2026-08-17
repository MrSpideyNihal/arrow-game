import 'package:flutter/material.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../domain/engine/level_generator.dart';
import '../../../l10n/app_strings.dart';
import '../../../main.dart';

/// Daily challenge screen. Generates a level from the current date seed.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  bool _rewardClaimed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header.
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.dailyChallenge,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),

              const Spacer(),

              // Date display.
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_monthName(now.month)} ${now.day}, ${now.year}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A unique puzzle for today',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final level = LevelGenerator.generate(
                            30 + (now.day % 30),
                            dateSeed,
                          );
                          Navigator.of(context).pushNamed(
                            AppRouter.gameplay,
                            arguments: level,
                          );
                        },
                        child: const Text('Start Challenge'),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Double reward button with Rewarded Ad
              if (!_rewardClaimed)
                TextButton.icon(
                  onPressed: _claimDoubleReward,
                  icon: Icon(Icons.play_circle_outline_rounded,
                      color: theme.colorScheme.primary),
                  label: Text(
                    'Watch ad for +${appConfig.economy.sparksPerDailyChallenge} Sparks',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Reward Claimed!',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimDoubleReward() async {
    final ads = AdsService(config: appConfig.ads);
    await ads.showRewardedAd(
      context: context,
      trigger: 'daily_double_reward',
      onUserEarnedReward: () async {
        final storage = StorageService();
        await storage.initialize();
        final current = storage.getSparksBalance();
        await storage.saveSparksBalance(
            current + appConfig.economy.sparksPerDailyChallenge);

        if (mounted) {
          setState(() => _rewardClaimed = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '+${appConfig.economy.sparksPerDailyChallenge} Sparks Claimed!'),
            ),
          );
        }
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
