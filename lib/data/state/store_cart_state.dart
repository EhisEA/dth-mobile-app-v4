import "dart:async";

import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Shared store cart session — badge, fetch, add / update / remove.
///
/// Qty / selection / remove are optimistic (like post reactions): the UI
/// updates immediately, then the API runs. Failures roll back or re-fetch.
class StoreCartState extends ChangeNotifier {
  StoreCartState(this._repo);

  final StoreRepo _repo;

  StoreCartData? _cart;
  ViewModelState _loadState = const ViewModelState.idle();
  int _count = 0;
  bool _adding = false;

  /// Once true, badge count comes from cart API / mutations — never from the
  /// stale `GET /stores/{store}` `cart_count` seed.
  bool _authoritative = false;

  StoreCartData? get cart => _cart;
  ViewModelState get loadState => _loadState;
  int get count => _count;
  bool get adding => _adding;
  bool get hasItems => _count > 0;
  bool get isAuthoritative => _authoritative;
  List<StoreCartStoreBlock> get stores => _cart?.stores ?? const [];
  List<StoreCartItem> get allItems => _cart?.allItems ?? const [];
  String get currencySymbol =>
      _cart?.currency.symbol.isNotEmpty == true
      ? _cart!.currency.symbol
      : "₦";

  bool get canCheckout =>
      stores.any((s) => s.isOpen && s.hasSelectedCheckoutable);

  StoreCartStoreBlock? get checkoutStore {
    for (final store in stores) {
      if (store.isOpen && store.hasSelectedCheckoutable) return store;
    }
    return null;
  }

  List<StoreCartStoreBlock> storesFor(StoreKind kind) => [
    for (final store in stores)
      if (store.kind == kind) store,
  ];

  int countFor(StoreKind kind) => storesFor(kind).fold<int>(
    0,
    (sum, store) =>
        sum + store.items.fold<int>(0, (s, item) => s + item.quantity),
  );

  bool canCheckoutFor(StoreKind kind) =>
      storesFor(kind).any((s) => s.isOpen && s.hasSelectedCheckoutable);

  StoreCartStoreBlock? checkoutStoreFor(StoreKind kind) {
    for (final store in storesFor(kind)) {
      if (store.isOpen && store.hasSelectedCheckoutable) return store;
    }
    return null;
  }

  int _sumItemQuantities() =>
      allItems.fold<int>(0, (sum, item) => sum + item.quantity);

  void _setCountFromItems() {
    _count = _sumItemQuantities();
    _authoritative = true;
  }

  /// Seed badge from `GET /stores/{store}` `cart_count` (first paint only).
  void syncCount(int count) {
    if (_authoritative) return;
    final next = count < 0 ? 0 : count;
    if (_count == next) return;
    _count = next;
    notifyListeners();
  }

  Future<void> fetchCart({bool quiet = false}) async {
    if (!quiet) {
      _loadState = const ViewModelState.busy();
      notifyListeners();
    }
    try {
      final cart = await _repo.getCart();
      _cart = cart;
      _count = cart.count < 0 ? _sumItemQuantities() : cart.count;
      _authoritative = true;
      _loadState = const ViewModelState.idle();
      notifyListeners();
    } on ApiFailure catch (e) {
      if (!quiet) {
        _loadState = ViewModelState.error(e);
        notifyListeners();
      } else {
        rethrow;
      }
    } catch (e) {
      if (!quiet) {
        _loadState = ViewModelState.error(ApiFailure(e.toString()));
        notifyListeners();
      } else {
        rethrow;
      }
    }
  }

  /// After a paid order: clear local cart immediately, then sync from API.
  Future<void> clearAfterCheckout() async {
    final currency = _cart?.currency ?? const StoreCurrencyDto(code: "", symbol: "₦");
    _cart = StoreCartData(currency: currency, count: 0, stores: const []);
    _count = 0;
    _authoritative = true;
    _loadState = const ViewModelState.idle();
    notifyListeners();
    try {
      await fetchCart(quiet: true);
    } catch (_) {
      // Keep the local empty cart if the refresh fails.
    }
  }

  /// `POST /api/store/cart/items`. Updates [count] from the response.
  Future<StoreCartAddResult> addItem({
    required String variantUid,
    required int quantity,
  }) async {
    final uid = variantUid.trim();
    if (uid.isEmpty) {
      throw ApiFailure("Select a size to continue.");
    }
    final qty = quantity.clamp(1, 1000);
    if (_adding) {
      throw ApiFailure("Adding to cart…");
    }

    _adding = true;
    notifyListeners();
    try {
      final result = await _repo.addCartItem(variantUid: uid, quantity: qty);
      _count = result.count < 0 ? _count : result.count;
      _authoritative = true;
      unawaited(fetchCart(quiet: true).catchError((_) {}));
      return result;
    } finally {
      _adding = false;
      notifyListeners();
    }
  }

  Future<void> setItemSelected(String itemUid, bool selected) async {
    await _updateItemOptimistic(itemUid, isSelected: selected);
  }

  Future<void> setItemQuantity(String itemUid, int quantity) async {
    await _updateItemOptimistic(
      itemUid,
      quantity: quantity.clamp(1, 1000),
    );
  }

  Future<void> incrementItem(String itemUid) async {
    final item = _findItem(itemUid);
    if (item == null) return;
    final max = item.maxPerOrder;
    final cap = max == null
        ? item.available
        : (max < item.available ? max : item.available);
    if (cap > 0 && item.quantity >= cap) {
      throw ApiFailure(
        max != null && max <= item.available
            ? "Maximum $max per order."
            : "Only ${item.available} left in stock.",
      );
    }
    await setItemQuantity(itemUid, item.quantity + 1);
  }

  Future<void> decrementItem(String itemUid) async {
    final item = _findItem(itemUid);
    if (item == null) return;
    if (item.quantity <= 1) return;
    await setItemQuantity(itemUid, item.quantity - 1);
  }

  Future<void> removeItem(String itemUid) async {
    final uid = itemUid.trim();
    final existing = _findItem(uid);
    if (existing == null) return;

    final snapshot = _cart;
    final snapshotCount = _count;
    _applyLocalRemove(uid);
    _setCountFromItems();
    notifyListeners();

    try {
      await _repo.removeCartItem(uid);
      // Authoritative refresh so badge / list stay in sync after delete.
      await fetchCart(quiet: true);
    } catch (e) {
      _cart = snapshot;
      _count = snapshotCount;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _updateItemOptimistic(
    String itemUid, {
    int? quantity,
    bool? isSelected,
  }) async {
    final uid = itemUid.trim();
    final existing = _findItem(uid);
    if (existing == null) return;

    final previous = existing;
    final previousCount = _count;
    final nextQty = quantity ?? existing.quantity;
    final nextSelected = isSelected ?? existing.isSelected;

    _patchItemLocally(
      uid,
      quantity: nextQty,
      isSelected: nextSelected,
    );
    if (quantity != null) {
      _setCountFromItems();
    } else {
      _authoritative = true;
    }
    notifyListeners();

    try {
      final result = await _repo.updateCartItem(
        uid,
        quantity: quantity,
        isSelected: isSelected,
      );
      final current = _findItem(uid);
      if (current == null) {
        unawaited(fetchCart(quiet: true).catchError((_) {}));
        return;
      }
      if (quantity != null && current.quantity != result.quantity) return;
      if (isSelected != null &&
          quantity == null &&
          current.isSelected != result.isSelected) {
        return;
      }
      _applyLocalUpdate(result);
      _setCountFromItems();
      notifyListeners();
      // Quiet refresh after edits so server count/problems stay accurate.
      unawaited(fetchCart(quiet: true).catchError((_) {}));
    } catch (e) {
      final current = _findItem(uid);
      final stillOurs =
          current != null &&
          current.quantity == nextQty &&
          current.isSelected == nextSelected;
      if (stillOurs) {
        _patchItemLocally(
          uid,
          quantity: previous.quantity,
          isSelected: previous.isSelected,
          lineTotal: previous.lineTotal,
        );
        _count = previousCount;
        notifyListeners();
      }
      rethrow;
    }
  }

  StoreCartItem? _findItem(String itemUid) {
    for (final item in allItems) {
      if (item.uid == itemUid) return item;
    }
    return null;
  }

  void _patchItemLocally(
    String itemUid, {
    required int quantity,
    required bool isSelected,
    int? lineTotal,
  }) {
    final cart = _cart;
    if (cart == null) return;
    final stores = <StoreCartStoreBlock>[];
    for (final store in cart.stores) {
      final items = store.items.map((item) {
        if (item.uid != itemUid) return item;
        return item.copyWith(
          quantity: quantity,
          isSelected: isSelected,
          lineTotal: lineTotal ?? item.unitPrice * quantity,
        );
      }).toList(growable: false);
      stores.add(
        store.copyWith(
          items: items,
          count: items.fold<int>(0, (s, i) => s + i.quantity),
        ),
      );
    }
    _cart = StoreCartData(
      currency: cart.currency,
      count: _count,
      stores: stores,
    );
  }

  void _applyLocalUpdate(StoreCartUpdateResult result) {
    final cart = _cart;
    if (cart == null) return;
    final stores = <StoreCartStoreBlock>[];
    for (final store in cart.stores) {
      final items = store.items.map((item) {
        if (item.uid != result.itemUid) return item;
        final qty = result.quantity;
        return item.copyWith(
          quantity: qty,
          isSelected: result.isSelected,
          lineTotal: item.unitPrice * qty,
        );
      }).toList(growable: false);
      stores.add(
        store.copyWith(
          items: items,
          count: items.fold<int>(0, (s, i) => s + i.quantity),
        ),
      );
    }
    _cart = StoreCartData(
      currency: cart.currency,
      count: _count,
      stores: stores,
    );
  }

  void _applyLocalRemove(String itemUid) {
    final cart = _cart;
    if (cart == null) return;
    final stores = <StoreCartStoreBlock>[];
    for (final store in cart.stores) {
      final nextItems = <StoreCartItem>[];
      for (final item in store.items) {
        if (item.uid == itemUid) continue;
        nextItems.add(item);
      }
      if (nextItems.isEmpty) continue;
      stores.add(
        store.copyWith(
          items: nextItems,
          count: nextItems.fold<int>(0, (s, i) => s + i.quantity),
        ),
      );
    }
    _cart = StoreCartData(
      currency: cart.currency,
      count: _count,
      stores: stores,
    );
  }

  void clear() {
    _cart = null;
    _count = 0;
    _adding = false;
    _authoritative = false;
    _loadState = const ViewModelState.idle();
    notifyListeners();
  }
}

final storeCartStateProvider = ChangeNotifierProvider<StoreCartState>((ref) {
  return StoreCartState(ref.read(storeRepositoryProvider));
});
