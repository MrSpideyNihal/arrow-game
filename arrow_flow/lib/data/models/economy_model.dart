/// Cosmetic item types.
enum CosmeticType { arrowSkin, boardTheme }

/// A cosmetic item that can be unlocked via total star milestones or Sparks.
class CosmeticItem {
  final String id;
  final String name;
  final CosmeticType type;
  final int starRequirement;
  final int sparksPrice;
  final String primaryColorHex;
  final String accentColorHex;
  final String? containerColorHex;
  final String? backgroundColorHex;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.type,
    required this.starRequirement,
    required this.sparksPrice,
    required this.primaryColorHex,
    required this.accentColorHex,
    this.containerColorHex,
    this.backgroundColorHex,
  });

  static const List<CosmeticItem> catalog = [
    // ──────────────────────────── 10 ARROW SKINS ────────────────────────────
    CosmeticItem(
      id: 'arrow_default',
      name: 'Pure Platinum (White)',
      type: CosmeticType.arrowSkin,
      starRequirement: 0,
      sparksPrice: 0,
      primaryColorHex: '#F8FAFC',
      accentColorHex: '#CBD5E1',
    ),
    CosmeticItem(
      id: 'arrow_cute_pink',
      name: 'Pink Vibes',
      type: CosmeticType.arrowSkin,
      starRequirement: 0,
      sparksPrice: 0,
      primaryColorHex: '#EC4899',
      accentColorHex: '#F472B6',
    ),
    CosmeticItem(
      id: 'arrow_neon_rush',
      name: 'Cyber Neon',
      type: CosmeticType.arrowSkin,
      starRequirement: 10,
      sparksPrice: 150,
      primaryColorHex: '#8B5CF6',
      accentColorHex: '#D946EF',
    ),
    CosmeticItem(
      id: 'arrow_lava_volcano',
      name: 'Volcano Core',
      type: CosmeticType.arrowSkin,
      starRequirement: 20,
      sparksPrice: 180,
      primaryColorHex: '#EF4444',
      accentColorHex: '#F97316',
    ),
    CosmeticItem(
      id: 'arrow_toxic_slime',
      name: 'Toxic Slime',
      type: CosmeticType.arrowSkin,
      starRequirement: 30,
      sparksPrice: 200,
      primaryColorHex: '#10B981',
      accentColorHex: '#34D399',
    ),
    CosmeticItem(
      id: 'arrow_solar_gold',
      name: 'Solar Gold',
      type: CosmeticType.arrowSkin,
      starRequirement: 40,
      sparksPrice: 250,
      primaryColorHex: '#F59E0B',
      accentColorHex: '#FDE047',
    ),
    CosmeticItem(
      id: 'arrow_obsidian_chrome',
      name: 'Obsidian Chrome',
      type: CosmeticType.arrowSkin,
      starRequirement: 50,
      sparksPrice: 280,
      primaryColorHex: '#64748B',
      accentColorHex: '#CBD5E1',
    ),
    CosmeticItem(
      id: 'arrow_cotton_candy',
      name: 'Cotton Candy',
      type: CosmeticType.arrowSkin,
      starRequirement: 60,
      sparksPrice: 300,
      primaryColorHex: '#38BDF8',
      accentColorHex: '#F472B6',
    ),
    CosmeticItem(
      id: 'arrow_plasma_void',
      name: 'Plasma Void',
      type: CosmeticType.arrowSkin,
      starRequirement: 70,
      sparksPrice: 320,
      primaryColorHex: '#A855F7',
      accentColorHex: '#818CF8',
    ),
    CosmeticItem(
      id: 'arrow_arctic_frost',
      name: 'Arctic Frost',
      type: CosmeticType.arrowSkin,
      starRequirement: 80,
      sparksPrice: 350,
      primaryColorHex: '#06B6D4',
      accentColorHex: '#67E8F9',
    ),

    // ──────────────────────────── 5 BOARD THEMES ────────────────────────────
    CosmeticItem(
      id: 'theme_default',
      name: 'Modern Slate',
      type: CosmeticType.boardTheme,
      starRequirement: 0,
      sparksPrice: 0,
      primaryColorHex: '#F8FAFC',
      accentColorHex: '#CBD5E1',
      backgroundColorHex: '#0B1120', // Sleek dark slate midnight canvas
      containerColorHex: '#1E293B', // Clean dark slate container
    ),
    CosmeticItem(
      id: 'theme_cute_pink',
      name: 'Pink Vibes',
      type: CosmeticType.boardTheme,
      starRequirement: 0,
      sparksPrice: 0,
      primaryColorHex: '#EC4899',
      accentColorHex: '#F472B6',
      backgroundColorHex: '#FFF0F5', // Soft pastel pink
      containerColorHex: '#FFFFFF', // White card container
    ),
    CosmeticItem(
      id: 'theme_neon_rush',
      name: 'Cyber Neon',
      type: CosmeticType.boardTheme,
      starRequirement: 15,
      sparksPrice: 350,
      primaryColorHex: '#D946EF',
      accentColorHex: '#8B5CF6',
      backgroundColorHex: '#0F172A',
      containerColorHex: '#1E1B4B',
    ),
    CosmeticItem(
      id: 'theme_lava_volcano',
      name: 'Volcano Core',
      type: CosmeticType.boardTheme,
      starRequirement: 35,
      sparksPrice: 450,
      primaryColorHex: '#EF4444',
      accentColorHex: '#F97316',
      backgroundColorHex: '#180808',
      containerColorHex: '#2C0D0D',
    ),
    CosmeticItem(
      id: 'theme_emerald_grove',
      name: 'Emerald Oasis',
      type: CosmeticType.boardTheme,
      starRequirement: 50,
      sparksPrice: 500,
      primaryColorHex: '#10B981',
      accentColorHex: '#34D399',
      backgroundColorHex: '#041F1A',
      containerColorHex: '#0B382F',
    ),
  ];
}

/// Economy and Cosmetics Player State.
class EconomyState {
  final int sparksBalance;
  final List<String> unlockedCosmetics;
  final String activeSkinId;
  final String activeThemeId;

  const EconomyState({
    required this.sparksBalance,
    required this.unlockedCosmetics,
    required this.activeSkinId,
    required this.activeThemeId,
  });

  factory EconomyState.initial() => const EconomyState(
        sparksBalance: 0,
        unlockedCosmetics: ['arrow_default', 'theme_default', 'arrow_cute_pink', 'theme_cute_pink'],
        activeSkinId: 'arrow_cute_pink',
        activeThemeId: 'theme_cute_pink',
      );

  EconomyState copyWith({
    int? sparksBalance,
    List<String>? unlockedCosmetics,
    String? activeSkinId,
    String? activeThemeId,
  }) {
    return EconomyState(
      sparksBalance: sparksBalance ?? this.sparksBalance,
      unlockedCosmetics: unlockedCosmetics ?? this.unlockedCosmetics,
      activeSkinId: activeSkinId ?? this.activeSkinId,
      activeThemeId: activeThemeId ?? this.activeThemeId,
    );
  }
}
