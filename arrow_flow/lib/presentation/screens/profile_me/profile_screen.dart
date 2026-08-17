import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/models/economy_model.dart';
import '../../../main.dart';
import 'cosmetics_sheet.dart';

/// Cosmetic Shop & Customization Hub — displays inline as a tab or as a pushed screen.
/// Players buy and equip 10 Arrow Color Skins and 5 Board Themes using Sparks.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = StorageService();
  int _sparks = 0;
  int _totalStars = 0;
  String _activeSkinId = 'arrow_default';
  String _activeThemeId = 'theme_default';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _storage.initialize();
    final repo = ProgressRepository(storageService: _storage);
    if (mounted) {
      setState(() {
        _sparks = _storage.getSparksBalance();
        _totalStars = repo.getTotalStars(appConfig.levels.bundledCount);
        _activeSkinId = _storage.getSetting<String>('active_skin', defaultValue: 'arrow_default')!;
        _activeThemeId = _storage.getSetting<String>('active_theme', defaultValue: 'theme_default')!;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this screen is pushed (has a route to pop) or embedded as a tab
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    final activeSkin = CosmeticItem.catalog.firstWhere(
      (i) => i.id == _activeSkinId,
      orElse: () => CosmeticItem.catalog.first,
    );
    final activeTheme = CosmeticItem.catalog.firstWhere(
      (i) => i.id == _activeThemeId,
      orElse: () => CosmeticItem.catalog.firstWhere((i) => i.id == 'theme_default'),
    );

    final themeAccentColor = _parseColor(activeTheme.primaryColorHex);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Row(
          children: [
            if (canPop)
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            if (canPop) const SizedBox(width: 8),
            const Text(
              'COSMETIC SHOP',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Balance Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeAccentColor.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeAccentColor.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: themeAccentColor.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFF59E0B),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPARKS BALANCE',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '$_sparks',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFDE047), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalStars Stars',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Watch Ad to Earn Sparks
        GestureDetector(
          onTap: () async {
            HapticsService().tap();
            final adsService = AdsService(config: appConfig.ads);
            await adsService.showRewardedAd(
              context: context,
              trigger: 'earn_sparks',
              onUserEarnedReward: () async {
                final bonus = appConfig.economy.rewardedAdSparksBonus;
                final currentSparks = _storage.getSparksBalance();
                await _storage.saveSparksBalance(currentSparks + bonus);
                AudioService(config: appConfig.audio).playComboTier();
                HapticsService().comboTier();
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '+$bonus Sparks earned! ✨',
                        style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      backgroundColor: const Color(0xFF34D399),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34D399).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WATCH AD → EARN SPARKS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+${appConfig.economy.rewardedAdSparksBonus} Sparks per video',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ABILITIES & BOOSTERS SHOP (Buy with Sparks)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ABILITIES & BOOSTERS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hint Pack (3 Hints for 60 Sparks)
              _BoosterShopTile(
                icon: Icons.lightbulb_outline_rounded,
                title: '3x Hint Pack',
                description: 'Highlights a free arrow',
                costSparks: 60,
                ownedCount: _storage.getBoosterCount(StorageService.boosterHints, defaultValue: 3),
                accentColor: const Color(0xFFF59E0B),
                onBuy: () => _buyBooster(StorageService.boosterHints, 60, 3, 'Hints'),
              ),

              const SizedBox(height: 12),

              // Bomb Pack (3 Bombs for 100 Sparks)
              _BoosterShopTile(
                icon: Icons.local_fire_department_rounded,
                title: '3x Bomb Pack',
                description: 'Vaporize ANY blocked arrow',
                costSparks: 100,
                ownedCount: _storage.getBoosterCount(StorageService.boosterBombs, defaultValue: 2),
                accentColor: const Color(0xFFEF4444),
                onBuy: () => _buyBooster(StorageService.boosterBombs, 100, 3, 'Bombs'),
              ),

              const SizedBox(height: 12),

              // Radar Pack (3 Radars for 120 Sparks - High-tier ability)
              _BoosterShopTile(
                icon: Icons.radar_rounded,
                title: '3x Radar Pack',
                description: 'Scan & reveal ALL playable arrows (3.5s)',
                costSparks: 120,
                ownedCount: _storage.getBoosterCount(StorageService.boosterRadars, defaultValue: 2),
                accentColor: const Color(0xFF06B6D4),
                onBuy: () => _buyBooster(StorageService.boosterRadars, 120, 3, 'Radars'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Active Equipment Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EQUIPPED COSMETICS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _EquippedTile(
                      title: 'Arrow Skin',
                      name: activeSkin.name,
                      colorHex: activeSkin.primaryColorHex,
                      accentHex: activeSkin.accentColorHex,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EquippedTile(
                      title: 'Board Theme',
                      name: activeTheme.name,
                      colorHex: activeTheme.primaryColorHex,
                      accentHex: activeTheme.containerColorHex ?? activeTheme.accentColorHex,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Open Full Shop CTA Button
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CosmeticsSheet(
                onStateChanged: _loadData,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeAccentColor, themeAccentColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeAccentColor.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'BROWSE ALL SKINS & THEMES',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Quick preview of all skins as colored circles
        const Text(
          'ARROW SKINS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: CosmeticItem.catalog
              .where((c) => c.type == CosmeticType.arrowSkin)
              .map((skin) {
            final isActive = skin.id == _activeSkinId;
            final primary = _parseColor(skin.primaryColorHex);
            final accent = _parseColor(skin.accentColorHex);
            final unlocked = _storage.getUnlockedCosmetics().contains(skin.id) || skin.sparksPrice == 0;
            return GestureDetector(
              onTap: () async {
                if (unlocked) {
                  await _storage.saveSetting('active_skin', skin.id);
                  if (mounted) {
                    setState(() => _activeSkinId = skin.id);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Equipped ${skin.name} arrow skin!'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CosmeticsSheet(onStateChanged: _loadData),
                  );
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primary, accent]),
                  border: Border.all(
                    color: isActive ? Colors.white : Colors.white24,
                    width: isActive ? 3 : 1,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: primary.withValues(alpha: 0.5), blurRadius: 12)]
                      : null,
                ),
                child: unlocked
                    ? (isActive
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null)
                    : Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.5), size: 16),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Quick preview of all themes as colored rectangles
        const Text(
          'BOARD THEMES',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: CosmeticItem.catalog
              .where((c) => c.type == CosmeticType.boardTheme)
              .map((theme) {
            final isActive = theme.id == _activeThemeId;
            final primary = _parseColor(theme.primaryColorHex);
            final bg = _parseColor(theme.backgroundColorHex ?? '#0D1B2A');
            final unlocked = _storage.getUnlockedCosmetics().contains(theme.id) || theme.sparksPrice == 0;
            return GestureDetector(
              onTap: () async {
                if (unlocked) {
                  await _storage.saveSetting('active_theme', theme.id);
                  final matchingSkinId = theme.id.replaceFirst('theme_', 'arrow_');
                  if (CosmeticItem.catalog.any((c) => c.id == matchingSkinId)) {
                    await _storage.saveSetting('active_skin', matchingSkinId);
                  }
                  if (mounted) {
                    setState(() {
                      _activeThemeId = theme.id;
                      if (CosmeticItem.catalog.any((c) => c.id == matchingSkinId)) {
                        _activeSkinId = matchingSkinId;
                      }
                    });
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Equipped ${theme.name} theme!'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CosmeticsSheet(onStateChanged: _loadData),
                  );
                }
              },
              child: Container(
                width: 64,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [bg, primary.withValues(alpha: 0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isActive ? Colors.white : Colors.white24,
                    width: isActive ? 2.5 : 1,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: primary.withValues(alpha: 0.5), blurRadius: 10)]
                      : null,
                ),
                child: Center(
                  child: unlocked
                      ? (isActive
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : null)
                      : Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.5), size: 14),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _buyBooster(String boosterKey, int cost, int amount, String name) async {
    final currentSparks = _storage.getSparksBalance();
    if (currentSparks < cost) {
      HapticsService().tap();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough Sparks! Need $cost Sparks (You have $currentSparks)',
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    await _storage.saveSparksBalance(currentSparks - cost);
    final currentCount = _storage.getBoosterCount(boosterKey);
    await _storage.saveBoosterCount(boosterKey, currentCount + amount);

    AudioService(config: appConfig.audio).playComboTier();
    HapticsService().comboTier();

    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '+$amount $name added to inventory! ✨',
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
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
}

class _BoosterShopTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int costSparks;
  final int ownedCount;
  final Color accentColor;
  final VoidCallback onBuy;

  const _BoosterShopTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.costSparks,
    required this.ownedCount,
    required this.accentColor,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$ownedCount owned',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '$costSparks',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquippedTile extends StatelessWidget {
  final String title;
  final String name;
  final String colorHex;
  final String accentHex;

  const _EquippedTile({
    required this.title,
    required this.name,
    required this.colorHex,
    required this.accentHex,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _parseColor(colorHex);
    final accent = _parseColor(accentHex);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
