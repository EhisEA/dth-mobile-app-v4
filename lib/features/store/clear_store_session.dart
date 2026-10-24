import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/view_model/store_checkout_view_model.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Drops in-memory store data so the next account on this device starts clean.
void clearStoreSession(ProviderContainer container) {
  container.read(storeCartStateProvider).clear();
  container.read(storeAddressesStateProvider).clear();
  container.read(storeStateProvider).clear();
  container.read(ordersStateProvider).clear();
  container.read(storeCheckoutViewModelProvider).reset();
}

/// Clears store data whenever a signed-in user becomes signed out.
///
/// Every logout path (logout sheet, delete account, 401 session expiry) ends
/// in [UserProfileState.logOut], which nulls the user after the server logout
/// and local auth clear have finished.
abstract final class StoreSessionGuard {
  static void bootstrap(ProviderContainer container) {
    final user = container.read(userStateProvider).user;
    var signedIn = user.value != null;
    user.addListener(() {
      final now = user.value != null;
      if (signedIn && !now) clearStoreSession(container);
      signedIn = now;
    });
  }
}
