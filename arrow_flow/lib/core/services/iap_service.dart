import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

/// Product definition model for In-App Purchases.
class IapProductItem {
  final String id;
  final String title;
  final String description;
  final String priceFormatted;
  final bool isConsumable;
  final int sparksAmount;
  final String iconEmoji;

  const IapProductItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priceFormatted,
    this.isConsumable = true,
    this.sparksAmount = 0,
    required this.iconEmoji,
  });
}

/// Service managing Google Play In-App Billing (IAP) products:
/// - sparks_small (100 Sparks)
/// - sparks_medium (500 Sparks)
/// - sparks_large (1500 Sparks)
/// - remove_ads (Remove All Ads forever - Non-consumable)
/// - booster_pack (5 Hints, 5 Bombs, 5 Radars - Consumable)
class IapService {
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final StorageService _storage = StorageService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _storeProducts = [];
  bool _isInitialized = false;

  /// Known Product IDs registered on Google Play Console
  static const String idSparksSmall = 'sparks_small';
  static const String idSparksMedium = 'sparks_medium';
  static const String idSparksLarge = 'sparks_large';
  static const String idRemoveAds = 'remove_ads';
  static const String idBoosterPack = 'booster_pack';

  static const Set<String> allProductIds = {
    idSparksSmall,
    idSparksMedium,
    idSparksLarge,
    idRemoveAds,
    idBoosterPack,
  };

  /// Fallback Catalog definitions when offline or testing
  static const List<IapProductItem> catalog = [
    IapProductItem(
      id: idSparksSmall,
      title: 'Pouch of Sparks',
      description: '100 Sparks to unlock skins and power-ups',
      priceFormatted: '\$0.99',
      isConsumable: true,
      sparksAmount: 100,
      iconEmoji: '✨',
    ),
    IapProductItem(
      id: idSparksMedium,
      title: 'Chest of Sparks',
      description: '500 Sparks (Most Popular)',
      priceFormatted: '\$2.99',
      isConsumable: true,
      sparksAmount: 500,
      iconEmoji: '💎',
    ),
    IapProductItem(
      id: idSparksLarge,
      title: 'Vault of Sparks',
      description: '1,500 Sparks (Best Value)',
      priceFormatted: '\$4.99',
      isConsumable: true,
      sparksAmount: 1500,
      iconEmoji: '👑',
    ),
    IapProductItem(
      id: idRemoveAds,
      title: 'Remove All Ads',
      description: 'Permanently remove interstitial & banner ads',
      priceFormatted: '\$1.99',
      isConsumable: false,
      sparksAmount: 0,
      iconEmoji: '🚫',
    ),
    IapProductItem(
      id: idBoosterPack,
      title: 'Super Booster Bundle',
      description: '+5 Hints, +5 Bombs, +5 Radars',
      priceFormatted: '\$0.99',
      isConsumable: true,
      sparksAmount: 0,
      iconEmoji: '⚡',
    ),
  ];

  bool get isAvailable => _isAvailable;
  bool get hasRemovedAds =>
      _storage.getSetting<bool>('has_removed_ads', defaultValue: false) ?? false;

  /// Callback when a purchase completes so UI can refresh immediately
  VoidCallback? onPurchaseCompleted;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _storage.initialize();

    try {
      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        final Stream<List<PurchaseDetails>> purchaseUpdated =
            _iap.purchaseStream;
        _subscription =
            purchaseUpdated.listen(_onPurchaseUpdate, onDone: () {
          _subscription?.cancel();
        }, onError: (error) {
          debugPrint('IAP purchaseStream error: $error');
        });

        // Query product details from Google Play Store
        final ProductDetailsResponse response =
            await _iap.queryProductDetails(allProductIds);
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('IAP Products not found in store: ${response.notFoundIDs}');
        }
        _storeProducts = response.productDetails;
      }
    } catch (e) {
      debugPrint('IAP initialization exception: $e');
    }

    _isInitialized = true;
  }

  /// Get formatted price for a given product ID (from store or fallback)
  String getPrice(String productId) {
    try {
      final storeItem =
          _storeProducts.where((p) => p.id == productId).firstOrNull;
      if (storeItem != null && storeItem.price.isNotEmpty) {
        return storeItem.price;
      }
    } catch (_) {}
    final fallback = catalog.where((p) => p.id == productId).firstOrNull;
    return fallback?.priceFormatted ?? '\$0.99';
  }

  /// Purchase a product by ID
  Future<bool> buyProduct(String productId) async {
    try {
      if (!_isAvailable) {
        // Fallback for web or dev environment: simulate purchase
        await _deliverProduct(productId);
        onPurchaseCompleted?.call();
        return true;
      }

      final storeItem =
          _storeProducts.where((p) => p.id == productId).firstOrNull;

      final PurchaseParam purchaseParam;
      if (storeItem != null) {
        purchaseParam = PurchaseParam(productDetails: storeItem);
      } else {
        // Fallback purchase param
        purchaseParam = PurchaseParam(
          productDetails: ProductDetails(
            id: productId,
            title: productId,
            description: '',
            price: '\$0.99',
            rawPrice: 0.99,
            currencyCode: 'USD',
          ),
        );
      }

      final fallback = catalog.where((p) => p.id == productId).firstOrNull;
      final isConsumable = fallback?.isConsumable ?? true;

      if (isConsumable) {
        return await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('Error buying product $productId: $e');
      // Dev/offline fallback delivery
      await _deliverProduct(productId);
      onPurchaseCompleted?.call();
      return true;
    }
  }

  /// Restores previous non-consumable purchases (e.g. Remove Ads)
  Future<void> restorePurchases() async {
    try {
      if (_isAvailable) {
        await _iap.restorePurchases();
      }
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _deliverProduct(purchaseDetails.productID);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
    onPurchaseCompleted?.call();
  }

  /// Deliver coins/sparks, boosters, or remove ads entitlement to player storage
  Future<void> _deliverProduct(String productId) async {
    await _storage.initialize();
    switch (productId) {
      case idSparksSmall:
        final current = _storage.getSparksBalance();
        await _storage.saveSparksBalance(current + 100);
        break;
      case idSparksMedium:
        final current = _storage.getSparksBalance();
        await _storage.saveSparksBalance(current + 500);
        break;
      case idSparksLarge:
        final current = _storage.getSparksBalance();
        await _storage.saveSparksBalance(current + 1500);
        break;
      case idRemoveAds:
        await _storage.saveSetting('has_removed_ads', true);
        break;
      case idBoosterPack:
        final hints = _storage.getBoosterCount(StorageService.boosterHints);
        final bombs = _storage.getBoosterCount(StorageService.boosterBombs);
        final radars = _storage.getBoosterCount(StorageService.boosterRadars);
        await _storage.saveBoosterCount(StorageService.boosterHints, hints + 5);
        await _storage.saveBoosterCount(StorageService.boosterBombs, bombs + 5);
        await _storage.saveBoosterCount(StorageService.boosterRadars, radars + 5);
        break;
      default:
        break;
    }
    debugPrint('Successfully delivered product: $productId');
  }

  void dispose() {
    _subscription?.cancel();
  }
}
