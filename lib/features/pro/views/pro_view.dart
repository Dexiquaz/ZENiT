import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/providers/pro_access_provider.dart';

class ProView extends ConsumerStatefulWidget {
  const ProView({super.key});

  @override
  ConsumerState<ProView> createState() => _ProViewState();
}

class _ProViewState extends ConsumerState<ProView> {
  String? _buyingProductId;
  bool _restoring = false;

  // Which tile the user has tapped/selected
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    final proState = ref.watch(proAccessProvider);
    final productsState = ref.watch(allProProductsProvider);
    final storeAvailabilityState = ref.watch(storeAvailabilityProvider);

    final isPro = proState.hasValue ? proState.value! : false;
    final storeUnavailable =
        storeAvailabilityState.hasValue && !storeAvailabilityState.value!;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Text(
            isPro ? 'YOU\'RE ALL SET' : 'UNLOCK ZENIT PRO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPro
                ? 'All premium features are unlocked on this device.'
                : 'Private, offline, ad-free. Pay once or subscribe.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ── Feature list ────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's included",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FeatureLine(
                    icon: Icons.all_inclusive,
                    text: 'Unlimited habits & tasks',
                  ),
                  const SizedBox(height: 8),
                  const _FeatureLine(
                    icon: Icons.flip,
                    text: 'Ambient Focus View',
                  ),
                  const SizedBox(height: 8),
                  const _FeatureLine(
                    icon: Icons.bar_chart,
                    text: 'Advanced Focus insights (next phase)',
                  ),
                  const SizedBox(height: 8),
                  const _FeatureLine(
                    icon: Icons.lock_outline,
                    text: 'Support private, ad-free development',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Pricing tiles ───────────────────────────────────────────────────
          if (!isPro) ...[
            if (storeUnavailable)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Store unavailable on this device.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              productsState.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) =>
                    const Center(child: Text('Could not load store prices.')),
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text('No products available right now.'),
                    );
                  }

                  return Column(
                    children: products.map((product) {
                      return _PricingTile(
                        product: product,
                        isSelected: _selectedProductId == product.id,
                        isBuying: _buyingProductId == product.id,
                        onTap: _buyingProductId != null
                            ? null
                            : () => setState(
                                () => _selectedProductId = product.id,
                              ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 16),

            // ── Buy button ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _selectedProductId == null ||
                        _buyingProductId != null ||
                        storeUnavailable
                    ? null
                    : () => _buySelected(context),
                icon: _buyingProductId != null
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.workspace_premium_outlined),
                label: Text(
                  _buyingProductId != null ? 'PROCESSING...' : 'GET PRO',
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Restore button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _restoring || storeUnavailable
                    ? null
                    : () => _restorePurchases(context),
                icon: _restoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: Text(_restoring ? 'RESTORING...' : 'RESTORE PURCHASES'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Subscriptions auto-renew. Cancel anytime.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          // ── Already pro ─────────────────────────────────────────────────────
          if (isPro)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ZENiT Pro is active on this device.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
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

  Future<void> _buySelected(BuildContext context) async {
    final productId = _selectedProductId;
    if (productId == null) return;

    final products = ref.read(allProProductsProvider).value ?? [];
    final product = products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == productId,
      orElse: () => null,
    );

    if (product == null) return;

    setState(() => _buyingProductId = productId);
    try {
      await ref.read(proAccessProvider.notifier).buyPro(product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Purchase flow started.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _buyingProductId = null);
    }
  }

  Future<void> _restorePurchases(BuildContext context) async {
    setState(() => _restoring = true);
    try {
      await ref.read(proAccessProvider.notifier).restorePurchases();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore request sent to store.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }
}

// ── Pricing Tile ──────────────────────────────────────────────────────────────

class _PricingTile extends StatelessWidget {
  const _PricingTile({
    required this.product,
    required this.isSelected,
    required this.isBuying,
    required this.onTap,
  });

  final ProductDetails product;
  final bool isSelected;
  final bool isBuying;
  final VoidCallback? onTap;

  String get _label {
    switch (product.id) {
      case zenitProMonthlyProductId:
        return 'Monthly';
      case zenitProYearlyProductId:
        return 'Yearly';
      case zenitProLifetimeProductId:
        return 'Lifetime';
      default:
        return product.title;
    }
  }

  String? get _badge {
    switch (product.id) {
      case zenitProYearlyProductId:
        return 'BEST VALUE';
      case zenitProLifetimeProductId:
        return 'ONE-TIME';
      default:
        return null;
    }
  }

  String get _description {
    switch (product.id) {
      case zenitProMonthlyProductId:
        return 'Billed every month';
      case zenitProYearlyProductId:
        return 'Billed once a year';
      case zenitProLifetimeProductId:
        return 'Pay once, own forever';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = _badge;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),

              // Label + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Text(
                product.price,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isSelected ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature Line ──────────────────────────────────────────────────────────────

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
