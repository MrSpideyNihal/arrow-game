import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../main.dart';
import '../../state/gameplay_providers.dart';

/// Level select screen — premium dark theme with rich card tiles.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  ProgressRepository? _progressRepo;
  LevelRepository? _levelRepo;
  bool _isLoading = true;
  late AnimationController _enterController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    await _storage.initialize();
    _progressRepo = ProgressRepository(storageService: _storage);
    _levelRepo = LevelRepository(config: appConfig.levels);
    await _levelRepo!.loadBundledPack();
    if (mounted) {
      setState(() => _isLoading = false);
      _enterController.forward();
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelCount = appConfig.levels.bundledCount;
    final progressState = ref.watch(progressProvider);
    final unlockedLevelId = progressState.unlockedLevelId;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'SELECT LEVEL',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$levelCount Levels',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF93C5FD),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Difficulty legend
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _DiffLegend('Easy', const Color(0xFF34D399)),
                  const SizedBox(width: 12),
                  _DiffLegend('Normal', const Color(0xFF60A5FA)),
                  const SizedBox(width: 12),
                  _DiffLegend('Hard', const Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  _DiffLegend('Expert', const Color(0xFFEF4444)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Level grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: levelCount,
                        itemBuilder: (context, index) {
                          final levelIndex = index + 1;
                          final progress = _progressRepo!
                              .getLevelProgress(levelIndex);

                          final isLocked = levelIndex > unlockedLevelId;
                          final diffColor = _difficultyColor(levelIndex);

                          return _LevelTile(
                            levelIndex: levelIndex,
                            stars: progress.stars,
                            isLocked: isLocked,
                            difficultyColor: diffColor,
                            onTap: () => _startLevel(context, levelIndex),
                          );
                        },
                      ),
                    ),
            ),

            // Banner Ad
            AdsService(config: appConfig.ads)
                .buildBannerAdWidget(placement: 'level_select'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(int levelIndex) {
    if (levelIndex <= 10) return const Color(0xFF34D399); // Easy - green
    if (levelIndex <= 25) return const Color(0xFF60A5FA); // Normal - blue
    if (levelIndex <= 36) return const Color(0xFFF59E0B); // Hard - amber
    return const Color(0xFFEF4444); // Expert - red
  }

  Future<void> _startLevel(BuildContext context, int levelIndex) async {
    Level level;
    try {
      level = await _levelRepo!.getLevel(levelIndex);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamed(
      AppRouter.gameplay,
      arguments: level,
    );
  }
}

class _DiffLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _DiffLegend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Premium level tile with difficulty color accent and star indicator.
class _LevelTile extends StatefulWidget {
  final int levelIndex;
  final int stars;
  final bool isLocked;
  final Color difficultyColor;
  final VoidCallback onTap;

  const _LevelTile({
    required this.levelIndex,
    required this.stars,
    required this.isLocked,
    required this.difficultyColor,
    required this.onTap,
  });

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile>
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
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
      onTapDown: widget.isLocked ? null : (_) => _pressController.forward(),
      onTapUp: widget.isLocked
          ? null
          : (_) {
              _pressController.reverse();
              widget.onTap();
            },
      onTapCancel:
          widget.isLocked ? null : () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.isLocked
                ? const Color(0xFF1A2535)
                : const Color(0xFF1E2D45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isLocked
                  ? Colors.white.withValues(alpha: 0.05)
                  : widget.difficultyColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: widget.isLocked
                ? null
                : [
                    BoxShadow(
                      color: widget.difficultyColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.isLocked
              ? Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.2),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Level number
                    Text(
                      '${widget.levelIndex}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: widget.stars > 0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Star indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Icon(
                          i < widget.stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 8,
                          color: i < widget.stars
                              ? widget.difficultyColor
                              : Colors.white.withValues(alpha: 0.15),
                        );
                      }),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
