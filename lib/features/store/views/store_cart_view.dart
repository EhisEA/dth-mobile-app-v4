import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCartView extends ConsumerStatefulWidget {
  const StoreCartView({super.key, required this.kind});

  final StoreKind kind;

  static const String path = NavigatorRoutes.storeCart;

  @override
  ConsumerState<StoreCartView> createState() => _StoreCartViewState();
}

class _StoreCartViewState extends ConsumerState<StoreCartView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(storeCartStateProvider).fetchCart());
    });
  }

  Future<void> _runCartAction(Future<void> Function() action) async {
    try {
      await action();
    } on ApiFailure catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(title: "Cart", message: e.message);
    } catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(title: "Cart", message: e.toString());
    }
  }

  Future<void> _proceedToCheckout(StoreCartStoreBlock checkoutStore) async {
    HapticFeedback.lightImpact();
    // Warm addresses while the quote loads so checkout feels snappy.
    unawaited(ref.read(storeAddressesStateProvider).fetchAddresses());
    final checkout = ref.read(storeCheckoutViewModelProvider);
    final addressUid = ref.read(cartViewModelProvider).shippingAddress?.uid;
    final ok = await checkout.load(checkoutStore.kind, addressUid: addressUid);
    if (!mounted || !ok) return;

    final quotedAddress = checkout.quote?.address;
    if (quotedAddress != null) {
      ref
          .read(cartViewModelProvider)
          .setShippingAddress(quotedAddress.toShippingAddress());
    }

    MobileNavigationService.instance.navigateTo(
      StoreCheckoutView.path,
      extra: {RoutingArgumentKey.storeCheckoutKind: checkoutStore.kind.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(storeCartStateProvider);
    final checkoutVm = ref.watch(storeCheckoutViewModelProvider);
    final kind = widget.kind;
    final stores = [
      for (final store in cart.storesFor(kind))
        if (store.items.isNotEmpty) store,
    ];
    final items = [for (final store in stores) ...store.items];
    final canCheckout = cart.canCheckoutFor(kind);
    final checkoutStore = cart.checkoutStoreFor(kind);
    final quoting = checkoutVm.isQuoteBusy;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const DthAppBar(title: "My Cart"),
      body: Column(
        children: [
          Expanded(
            child: cart.loadState.when(
              busy: () => const StoreCartSkeleton(),
              error: (failure) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StoreEmptyState(
                        title: "Couldn't load cart",
                        message: failure.message,
                      ),
                      Gap.h16,
                      AppButton.onBorder(
                        text: "Retry",
                        isShort: true,
                        width: 140,
                        press: () => unawaited(cart.fetchCart()),
                      ),
                    ],
                  ),
                ),
              ),
              idle: () {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Gap.h30,
                        Gap.h30,
                        const StoreEmptyState(
                          title: "Your Cart is Empty",
                          message:
                              "Your cart is empty at the moment. Kindly add an item to your cart and it will appear here.",
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => cart.fetchCart(quiet: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: stores.length,
                    itemBuilder: (context, storeIndex) {
                      final store = stores[storeIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stores.length > 1) ...[
                            if (storeIndex > 0) Gap.h16,
                            AppText.semiBold(
                              store.name,
                              fontSize: 14,
                              color: AppColors.blackTint20,
                            ),
                            Gap.h4,
                          ],
                          ...store.items.map((item) {
                            return Column(
                              children: [
                                StoreCartLineTile(
                                  item: item,
                                  currencySymbol: cart.currencySymbol,
                                  onToggleSelected: () => unawaited(
                                    _runCartAction(
                                      () => cart.setItemSelected(
                                        item.uid,
                                        !item.isSelected,
                                      ),
                                    ),
                                  ),
                                  onIncrement: () => unawaited(
                                    _runCartAction(
                                      () => cart.incrementItem(item.uid),
                                    ),
                                  ),
                                  onDecrement: () => unawaited(
                                    _runCartAction(
                                      () => cart.decrementItem(item.uid),
                                    ),
                                  ),
                                  onRemove: () async {
                                    final ok = await showRemoveCartItemSheet(
                                      context,
                                    );
                                    if (!ok) return;
                                    await _runCartAction(
                                      () => cart.removeItem(item.uid),
                                    );
                                  },
                                ),
                                Container(
                                  height: 1,
                                  color: AppColors.greyTint20,
                                ),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: AppButton.primary(
                text: "Proceed to checkout",
                enabled: canCheckout && checkoutStore != null && !quoting,
                isLoading: quoting,
                suffixIcon: quoting
                    ? null
                    : Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: canCheckout ? AppColors.white : AppColors.tint15,
                      ),
                press: canCheckout && checkoutStore != null && !quoting
                    ? () => unawaited(_proceedToCheckout(checkoutStore))
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
