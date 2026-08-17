import 'package:flutter/material.dart';
import '../../../data/models/economy_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../main.dart';

/// Modal bottom sheet & full shop interface for browsing, unlocking, and equipping
/// 10 Arrow Color Skins and 5 Board Themes.
class CosmeticsSheet extends StatefulWidget {
  final VoidCallback onStateChanged;

  const CosmeticsSheet({super.key, required this.onStateChanged});

  @override
  State<CosmeticsSheet> createState() => _CosmeticsSheetState();
}

class _CosmeticsSheetState extends State<CosmeticsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = StorageService();
  int _sparksBalance = 0;
  List<String> _unlockedIds = [];
  String _activeSkinId = 'arrow_default';
  String _activeThemeId = 'theme_default';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _storage.initialize();
    setState(() {
      _sparksBalance = _storage.getSparksBalance();
      _unlockedIds = [
        'arrow_default',
        'theme_default',
        'theme_cute_pink',
        'arrow_cute_pink',
        ..._storage.getUnlockedCosmetics()
      ];
      _activeSkinId = _storage.getSetting<String>('active_skin',
          defaultValue: 'arrow_default')!;
      _activeThemeId = _storage.getSetting<String>('active_theme',
          defaultValue: 'theme_default')!;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    final arrowSkins = CosmeticItem.catalog
        .where((i) => i.type == CosmeticType.arrowSkin)
        .toList();
    final boardThemes = CosmeticItem.catalog
        .where((i) => i.type == CosmeticType.boardTheme)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Sparks balance
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COSMETIC SHOP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Customize Arrow Skins & Board Themes',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text(
                      '$_sparksBalance Sparks',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom TabBar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'ARROW SKINS (10)'),
                Tab(text: 'BOARD THEMES (5)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSkinsGrid(arrowSkins),
                _buildThemesGrid(boardThemes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinsGrid(List<CosmeticItem> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isUnlocked = _unlockedIds.contains(item.id) || item.sparksPrice == 0;
        final isActive = item.id == _activeSkinId;
        final primaryColor = _parseHex(item.primaryColorHex);
        final accentColor = _parseHex(item.accentColorHex);

        return GestureDetector(
          onTap: () => _handleItemTap(item, isUnlocked, isActive),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryColor.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? primaryColor
                    : Colors.white.withValues(alpha: 0.12),
                width: isActive ? 2.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'EQUIPPED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else if (isUnlocked)
                  const Text(
                    'EQUIP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF60A5FA),
                      letterSpacing: 1,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.sparksPrice}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemesGrid(List<CosmeticItem> items) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isUnlocked = _unlockedIds.contains(item.id) || item.sparksPrice == 0;
        final isActive = item.id == _activeThemeId;
        final bgColor = _parseHex(item.backgroundColorHex ?? '#0D1B2A');
        final containerColor = _parseHex(item.containerColorHex ?? '#0B1E30');
        final accentColor = _parseHex(item.primaryColorHex);

        // Calculate card contrast dynamically for light themes (Pink Vibes)
        final isLightCard = bgColor.computeLuminance() > 0.45 || containerColor.computeLuminance() > 0.45;
        final titleColor = isLightCard ? const Color(0xFF831843) : Colors.white;
        final descColor = isLightCard ? const Color(0xFF9D174D) : Colors.white.withValues(alpha: 0.6);

        return GestureDetector(
          onTap: () => _handleItemTap(item, isUnlocked, isActive),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgColor, containerColor],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? accentColor : (isLightCard ? const Color(0xFFF472B6) : Colors.white.withValues(alpha: 0.15)),
                width: isActive ? 3 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentColor, width: 2),
                  ),
                  child: Icon(Icons.grid_4x4_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.id == 'theme_cute_pink'
                            ? 'Cute Pastel Pink & Rose Theme'
                            : item.id == 'theme_neon_rush'
                                ? 'Cyberpunk Synthwave Glow'
                                : item.id == 'theme_lava_volcano'
                                    ? 'Infernal Magma & Obsidian Theme'
                                    : item.id == 'theme_emerald_grove'
                                        ? 'Calm Forest Emerald Theme'
                                        : 'Classic Dark Tech Aesthetic',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: isLightCard ? FontWeight.w600 : FontWeight.normal,
                          color: descColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLightCard
                          ? const Color(0xFF831843).withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLightCard ? const Color(0xFF831843) : Colors.white30,
                      ),
                    ),
                    child: Text(
                      'APPLY',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLightCard ? const Color(0xFF831843) : Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          '${item.sparksPrice}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleItemTap(CosmeticItem item, bool isUnlocked, bool isActive) async {
    HapticsService().tap();
    AudioService(config: appConfig.audio).playTap();

    if (isActive) return;

    if (isUnlocked) {
      if (item.type == CosmeticType.arrowSkin) {
        await _storage.saveSetting('active_skin', item.id);
        setState(() => _activeSkinId = item.id);
      } else {
        await _storage.saveSetting('active_theme', item.id);
        final matchingSkinId = item.id.replaceFirst('theme_', 'arrow_');
        if (CosmeticItem.catalog.any((c) => c.id == matchingSkinId)) {
          await _storage.saveSetting('active_skin', matchingSkinId);
          setState(() => _activeSkinId = matchingSkinId);
        }
        setState(() => _activeThemeId = item.id);
      }
      widget.onStateChanged();
    } else {
      if (_sparksBalance >= item.sparksPrice) {
        final newBalance = _sparksBalance - item.sparksPrice;
        await _storage.saveSparksBalance(newBalance);
        final unlocked = _storage.getUnlockedCosmetics();
        if (!unlocked.contains(item.id)) {
          await _storage.saveUnlockedCosmetics([...unlocked, item.id]);
        }
        if (item.type == CosmeticType.arrowSkin) {
          await _storage.saveSetting('active_skin', item.id);
        } else {
          await _storage.saveSetting('active_theme', item.id);
          final matchingSkinId = item.id.replaceFirst('theme_', 'arrow_');
          if (CosmeticItem.catalog.any((c) => c.id == matchingSkinId)) {
            await _storage.saveSetting('active_skin', matchingSkinId);
          }
        }
        HapticsService().comboTier();
        AudioService(config: appConfig.audio).playComboTier();
        await _loadData();
        widget.onStateChanged();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Need ${item.sparksPrice - _sparksBalance} more Sparks to unlock ${item.name}!',
              style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
