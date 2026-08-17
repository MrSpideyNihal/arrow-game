/// Stub interface for the Remove Ads in-app purchase.
/// A real store SDK (e.g. in_app_purchase) can be dropped in behind this
/// interface later without changing any calling code.
abstract class IapService {
  /// Whether the user has purchased Remove Ads.
  bool get hasRemovedAds;

  /// Initiates the Remove Ads purchase flow.
  Future<bool> purchaseRemoveAds();

  /// Restores previous purchases (e.g. after reinstall).
  Future<bool> restorePurchases();
}

/// Default stub that always reports ads as not removed.
/// Replace with a real implementation when connecting to a store SDK.
class StubIapService implements IapService {
  final bool _hasRemovedAds = false;

  @override
  bool get hasRemovedAds => _hasRemovedAds;

  @override
  Future<bool> purchaseRemoveAds() async {
    // Stub: in production, this would launch the store purchase flow.
    return false;
  }

  @override
  Future<bool> restorePurchases() async {
    // Stub: in production, this would query the store for prior purchases.
    return false;
  }
}
