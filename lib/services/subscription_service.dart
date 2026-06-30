import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _productId = 'smart_closet_monthly';
  static const String _prefKey = 'subscription_active';
  static const String _trialStartKey = 'trial_start_date';
  static const int _trialDays = 7;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  // On web, subscriptions are not supported — grant full access
  bool get isAvailable => !kIsWeb;

  /// Fetches the localized subscription price string from the store
  /// (e.g. "€10.00", "$10.99"). Falls back to "€10" when the product
  /// cannot be loaded (e.g. on web or before the IAP is approved).
  Future<String> getPriceString() async {
    if (kIsWeb) return '€10';
    try {
      final response = await _iap.queryProductDetails({_productId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        return _product!.price;
      }
    } catch (e) {
      debugPrint('Price fetch error: $e');
    }
    return '€10';
  }

  /// Re-syncs entitlements with the App Store. Returns the resulting
  /// subscription status so the UI can react to a successful restore.
  Future<bool> restorePurchases() async {
    await _restorePurchases();
    return _isSubscribed;
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      _isSubscribed = true;
      return;
    }

    await _loadFromPrefs();

    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => debugPrint('IAP stream error: $e'),
    );

    await _restorePurchases();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(_prefKey) ?? false;

    // Check trial period
    if (!_isSubscribed) {
      final trialStartStr = prefs.getString(_trialStartKey);
      if (trialStartStr != null) {
        final trialStart = DateTime.parse(trialStartStr);
        final daysSinceStart = DateTime.now().difference(trialStart).inDays;
        if (daysSinceStart < _trialDays) {
          _isSubscribed = true; // Still in trial
        }
      }
    }
  }

  Future<void> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_trialStartKey) == null) {
      await prefs.setString(_trialStartKey, DateTime.now().toIso8601String());
      _isSubscribed = true;
    }
  }

  int get trialDaysRemaining {
    return _trialDays; // Default, will be updated from prefs
  }

  Future<int> getTrialDaysRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartStr = prefs.getString(_trialStartKey);
    if (trialStartStr == null) return _trialDays;
    final trialStart = DateTime.parse(trialStartStr);
    final daysPassed = DateTime.now().difference(trialStart).inDays;
    return (_trialDays - daysPassed).clamp(0, _trialDays);
  }

  Future<bool> hasTrialStarted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_trialStartKey) != null;
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  Future<bool> subscribe() async {
    if (kIsWeb) {
      _isSubscribed = true;
      return true;
    }

    try {
      final response = await _iap.queryProductDetails({_productId});
      if (response.productDetails.isEmpty) {
        debugPrint('Product not found: $_productId');
        return false;
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);

      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Subscribe error: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == _productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _setSubscribed(true);
        } else if (purchase.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchase.error}');
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _setSubscribed(bool value) async {
    _isSubscribed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
