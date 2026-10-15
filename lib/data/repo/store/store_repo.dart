import "package:dth_v4/data/models/store/store.dart";

abstract class StoreRepo {
  /// [store] is `event` or `merch`.
  Future<StoreInfoModel> getStore(String store);

  /// Category chips for [store] (`event` or `merch`). No synthetic "All" chip.
  Future<List<StoreCategoryDto>> getCategories(String store);

  /// Catalog products for [store] (`event` or `merch`), priced in the user's currency.
  Future<StoreProductsPage> getProducts(
    String store, {
    String? search,
    String? categoryUid,
    String? cursor,
    int perPage = 20,
  });

  /// Single product with images, colors, and stocked variants.
  Future<StoreProductDetailResult> getProduct(String store, String productId);

  /// `GET /api/store/cart`.
  Future<StoreCartData> getCart();

  /// `POST /api/store/cart/items` — add [quantity] of [variantUid] to the cart.
  Future<StoreCartAddResult> addCartItem({
    required String variantUid,
    required int quantity,
  });

  /// `PATCH /api/store/cart/items/{id}`.
  Future<StoreCartUpdateResult> updateCartItem(
    String itemUid, {
    int? quantity,
    bool? isSelected,
  });

  /// `DELETE /api/store/cart/items/{id}`.
  Future<void> removeCartItem(String itemUid);

  /// `POST /api/stores/{store}/checkout/quote` — read-only checkout summary.
  Future<StoreCheckoutQuote> quoteCheckout(
    String store, {
    String? promoCode,
    String? addressUid,
  });

  /// `POST /api/stores/{store}/checkout` — create order and start payment.
  Future<StoreCheckoutResult> checkout(
    String store, {
    String? promoCode,
    String? addressUid,
  });

  /// `GET /api/payment/verify/{reference}`.
  Future<void> verifyPayment({required String reference});

  /// `POST /api/store/orders/{order}/abandon` — leave payment without paying.
  ///
  /// Provider is checked first: when already paid, [StoreAbandonOrderResult.isPaid]
  /// is true and nothing is cancelled.
  Future<StoreAbandonOrderResult> abandonOrder(String orderUid);

  /// `GET /api/addresses` — default address first.
  Future<List<StoreCheckoutAddress>> getAddresses();

  /// `POST /api/addresses` — save a delivery address (max 5).
  Future<StoreCheckoutAddress> addAddress({
    required String buildingNumber,
    required String street,
    required String countryIso,
    required String state,
    required String city,
    required String phone,
    String? postalCode,
    bool isDefault = true,
  });

  /// `PUT /api/addresses/{address}`.
  Future<StoreCheckoutAddress> updateAddress(
    String addressUid, {
    required String buildingNumber,
    required String street,
    required String countryIso,
    required String state,
    required String city,
    required String phone,
    String? postalCode,
    bool isDefault = true,
  });

  /// `DELETE /api/addresses/{address}`.
  Future<void> deleteAddress(String addressUid);
}
