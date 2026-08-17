import '../../core/services/storage_service.dart';
import '../models/economy_model.dart';

/// Repository managing Sparks currency, unlocked cosmetics, and selected skin/theme.
class EconomyRepository {
  final StorageService storageService;

  EconomyRepository({required this.storageService});

  /// Loads current economy state.
  EconomyState getEconomyState() {
    final balance = storageService.getSparksBalance();
    final unlocked = storageService.getUnlockedCosmetics();
    final skin = storageService.getSetting<String>('active_skin',
        defaultValue: 'arrow_default')!;
    final theme = storageService.getSetting<String>('active_theme',
        defaultValue: 'theme_default')!;

    final defaultUnlocked = ['arrow_default', 'theme_default'];
    final allUnlocked = {...defaultUnlocked, ...unlocked}.toList();

    return EconomyState(
      sparksBalance: balance,
      unlockedCosmetics: allUnlocked,
      activeSkinId: skin,
      activeThemeId: theme,
    );
  }

  /// Adds [amount] of Sparks to balance.
  Future<int> addSparks(int amount) async {
    final current = storageService.getSparksBalance();
    final newBalance = current + amount;
    await storageService.saveSparksBalance(newBalance);
    return newBalance;
  }

  /// Deducts [amount] of Sparks if player has sufficient balance.
  Future<bool> deductSparks(int amount) async {
    final current = storageService.getSparksBalance();
    if (current < amount) return false;
    final newBalance = current - amount;
    await storageService.saveSparksBalance(newBalance);
    return true;
  }

  /// Unlocks a cosmetic item.
  Future<void> unlockItem(String itemId) async {
    final current = storageService.getUnlockedCosmetics();
    if (!current.contains(itemId)) {
      current.add(itemId);
      await storageService.saveUnlockedCosmetics(current);
    }
  }

  /// Sets active skin or theme.
  Future<void> selectCosmetic(CosmeticItem item) async {
    if (item.type == CosmeticType.arrowSkin) {
      await storageService.saveSetting('active_skin', item.id);
    } else {
      await storageService.saveSetting('active_theme', item.id);
    }
  }
}
