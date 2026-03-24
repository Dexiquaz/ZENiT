import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/secure_storage_helper.dart';

// ── Product IDs ───────────────────────────────────────────────────────────────
const zenitProLifetimeProductId = 'zenit_pro_lifetime';
const zenitProMonthlyProductId = 'zenit_pro_monthly'; // NEW
const zenitProYearlyProductId = 'zenit_pro_yearly'; // NEW

const zenitFreeHabitLimit = 5;
const zenitFreeActiveTaskLimit = 10;

// ── Everything below this line is unchanged until noted ───────────────────────

enum ProGateReason {
  entitlementUnavailable,
  noProEntitlement,
  freeLimitReached,
}

class ProGateDecision {
  const ProGateDecision({required this.allowed, this.reason, this.message});
  final bool allowed;
  final ProGateReason? reason;
  final String? message;
}

class ProFeatureLimitException implements Exception {
  const ProFeatureLimitException(this.message);
  final String message;
  @override
  String toString() => message;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final proAccessProvider = AsyncNotifierProvider<ProAccessNotifier, bool>(
  ProAccessNotifier.new,
);

// CHANGED: was proProductDetailsProvider (single). Now returns all 3 products.
final allProProductsProvider = FutureProvider<List<ProductDetails>>((
  ref,
) async {
  final notifier = ref.read(proAccessProvider.notifier);
  return notifier.getAllProProducts();
});

// KEPT for any existing code that uses it — now just returns the lifetime product
final proProductDetailsProvider = FutureProvider<ProductDetails?>((ref) async {
  final products = await ref.watch(allProProductsProvider.future);
  try {
    return products.firstWhere((p) => p.id == zenitProLifetimeProductId);
  } catch (_) {
    return null;
  }
});

final storeAvailabilityProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.read(proAccessProvider.notifier);
  return notifier.isStoreAvailable();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProAccessNotifier extends AsyncNotifier<bool> {
  static const _isProKey = 'entitlement_pro_unlocked';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isReconciling = false;

  @override
  Future<bool> build() async {
    ref.onDispose(() {
      _purchaseSubscription?.cancel();
      _purchaseSubscription = null;
    });
    return await SecureStorageHelper.getBool(_isProKey) ?? false;
  }

  Future<bool> isStoreAvailable() async {
    try {
      return await _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  // NEW: replaces getProProductDetails() — fetches all 3 products
  Future<List<ProductDetails>> getAllProProducts() async {
    final isAvailable = await isStoreAvailable();
    if (!isAvailable) return [];

    _startPurchaseListener();

    ProductDetailsResponse response;
    try {
      response = await _iap.queryProductDetails({
        zenitProLifetimeProductId,
        zenitProMonthlyProductId,
        zenitProYearlyProductId,
      });
    } catch (_) {
      return [];
    }

    if (response.error != null || response.productDetails.isEmpty) return [];

    // Sort into a consistent order: monthly → yearly → lifetime
    final order = [
      zenitProMonthlyProductId,
      zenitProYearlyProductId,
      zenitProLifetimeProductId,
    ];

    final sorted = [...response.productDetails]
      ..sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));

    return sorted;
  }

  // KEPT for backward compat
  Future<ProductDetails?> getProProductDetails() async {
    final products = await getAllProProducts();
    try {
      return products.firstWhere((p) => p.id == zenitProLifetimeProductId);
    } catch (_) {
      return null;
    }
  }

  // CHANGED: was buyProLifetime(). Now takes any ProductDetails.
  Future<void> buyPro(ProductDetails product) async {
    final isAvailable = await isStoreAvailable();
    if (!isAvailable) {
      throw StateError('Store is not available on this device.');
    }
    _startPurchaseListener();

    final purchaseParam = PurchaseParam(productDetails: product);

    // Both subscriptions and non-consumables use buyNonConsumable on Android
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // KEPT for backward compat — just calls buyPro with the lifetime product
  Future<void> buyProLifetime() async {
    final product = await getProProductDetails();
    if (product == null) {
      throw StateError('ZENiT Pro is not available right now.');
    }
    await buyPro(product);
  }

  // UNCHANGED
  Future<void> restorePurchases() async {
    final isAvailable = await isStoreAvailable();
    if (!isAvailable) {
      throw StateError('Store is not available on this device.');
    }
    _startPurchaseListener();
    await _iap.restorePurchases();
  }

  // UNCHANGED
  Future<void> reconcileEntitlement() async {
    if (_isReconciling) return;
    _isReconciling = true;
    try {
      final isAvailable = await isStoreAvailable();
      if (!isAvailable) return;
      _startPurchaseListener();
      await _iap.restorePurchases();
    } catch (_) {
    } finally {
      _isReconciling = false;
    }
  }

  // UNCHANGED
  ProGateDecision ambientViewDecision() => _resolveEntitlementFailClosed();

  ProGateDecision habitCreationDecision(int existingHabitCount) {
    if (!state.hasValue) {
      return const ProGateDecision(
        allowed: false,
        reason: ProGateReason.entitlementUnavailable,
        message: 'Pro entitlement is unavailable right now. Please try again.',
      );
    }
    if (state.value!) return const ProGateDecision(allowed: true);
    if (existingHabitCount >= zenitFreeHabitLimit) {
      return const ProGateDecision(
        allowed: false,
        reason: ProGateReason.freeLimitReached,
        message:
            'Free plan limit reached: up to 5 habits. Upgrade to ZENiT Pro for unlimited habits.',
      );
    }
    return const ProGateDecision(allowed: true);
  }

  ProGateDecision taskCreationDecision(int activeTaskCount) {
    if (!state.hasValue) {
      return const ProGateDecision(
        allowed: false,
        reason: ProGateReason.entitlementUnavailable,
        message: 'Pro entitlement is unavailable right now. Please try again.',
      );
    }
    if (state.value!) return const ProGateDecision(allowed: true);
    if (activeTaskCount >= zenitFreeActiveTaskLimit) {
      return const ProGateDecision(
        allowed: false,
        reason: ProGateReason.freeLimitReached,
        message:
            'Free plan limit reached: up to 10 active tasks. Upgrade to ZENiT Pro for unlimited tasks.',
      );
    }
    return const ProGateDecision(allowed: true);
  }

  Future<void> enforceHabitCreationLimit(int existingHabitCount) async {
    final decision = habitCreationDecision(existingHabitCount);
    if (!decision.allowed) {
      throw ProFeatureLimitException(
        decision.message ?? 'Pro entitlement is unavailable right now.',
      );
    }
  }

  Future<void> enforceTaskCreationLimit(int activeTaskCount) async {
    final decision = taskCreationDecision(activeTaskCount);
    if (!decision.allowed) {
      throw ProFeatureLimitException(
        decision.message ?? 'Pro entitlement is unavailable right now.',
      );
    }
  }

  // CHANGED: now accepts all 3 product IDs
  void _startPurchaseListener() {
    if (_purchaseSubscription != null) return;
    _purchaseSubscription = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase);
      }
    });
  }

  void _handlePurchase(PurchaseDetails purchase) {
    // CHANGED: check against all 3 IDs
    const validIds = {
      zenitProLifetimeProductId,
      zenitProMonthlyProductId,
      zenitProYearlyProductId,
    };

    if (!validIds.contains(purchase.productID)) return;

    final status = purchase.status;
    if (status == PurchaseStatus.purchased ||
        status == PurchaseStatus.restored) {
      unawaited(_unlockPro());
    }

    if (purchase.pendingCompletePurchase) {
      unawaited(_iap.completePurchase(purchase));
    }
  }

  Future<void> _unlockPro() async {
    await SecureStorageHelper.setBool(_isProKey, true);
    state = const AsyncData(true);
  }

  ProGateDecision _resolveEntitlementFailClosed() {
    if (!state.hasValue) {
      return const ProGateDecision(
        allowed: false,
        reason: ProGateReason.entitlementUnavailable,
        message: 'Pro entitlement is unavailable right now. Please try again.',
      );
    }
    if (state.value!) return const ProGateDecision(allowed: true);
    return const ProGateDecision(
      allowed: false,
      reason: ProGateReason.noProEntitlement,
    );
  }
}
