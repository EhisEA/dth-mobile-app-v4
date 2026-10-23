import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/view_model/cart_view_model.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Drops in-memory store data so the next account on this device starts clean.
void clearStoreSession(WidgetRef ref) {
  ref.read(storeCartStateProvider).clear();
  ref.read(storeAddressesStateProvider).clear();
  ref.read(storeStateProvider).clear();
  ref.read(ordersStateProvider).clear();
  ref.read(cartViewModelProvider).setShippingAddress(null);
}
