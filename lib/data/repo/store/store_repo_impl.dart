import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreRepoImpl implements StoreRepo {
  StoreRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<StoreInfoModel> getStore(String store) async {
    final response = await _networkService.get(ApiRoute.store(store));
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid store response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "This feature is not available.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Store could not be retrieved.",
      );
    }
    return StoreInfoModel.fromJson(data);
  }

  @override
  Future<List<StoreCategoryDto>> getCategories(String store) async {
    final response = await _networkService.get(ApiRoute.storeCategories(store));
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid categories response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Categories could not be retrieved.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Categories could not be retrieved.");
    }
    final list = data["categories"];
    if (list is! List<dynamic>) return const [];
    return list
        .whereType<Map>()
        .map((e) => StoreCategoryDto.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.uid.isNotEmpty && c.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<StoreProductsPage> getProducts(
    String store, {
    String? search,
    String? categoryUid,
    String? cursor,
    int perPage = 20,
  }) async {
    final response = await _networkService.get(
      ApiRoute.storeProducts(store),
      queryParams: _productParams(
        search: search,
        categoryUid: categoryUid,
        cursor: cursor,
        perPage: perPage,
      ),
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid products response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Products could not be retrieved.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Products could not be retrieved.",
      );
    }

    final currencyRaw = data["currency"];
    final currency = currencyRaw is Map
        ? StoreCurrencyDto.fromJson(Map<String, dynamic>.from(currencyRaw))
        : const StoreCurrencyDto(code: "", symbol: "");

    final productsOuter = data["products"];
    if (productsOuter is! Map<String, dynamic>) {
      return StoreProductsPage(
        currency: currency,
        products: const PaginatedResult(items: [], nextCursor: null),
      );
    }

    final list = productsOuter["data"];
    final items = list is List<dynamic>
        ? list
              .whereType<Map>()
              .map(
                (e) => StoreProductDto.fromJson(Map<String, dynamic>.from(e)),
              )
              .where((p) => p.uid.isNotEmpty)
              .toList(growable: false)
        : const <StoreProductDto>[];

    final cursorRaw = productsOuter["next_cursor"];
    final nextCursor = cursorRaw is String && cursorRaw.isNotEmpty
        ? cursorRaw
        : null;

    return StoreProductsPage(
      currency: currency,
      products: PaginatedResult(items: items, nextCursor: nextCursor),
    );
  }

  @override
  Future<StoreProductDetailResult> getProduct(
    String store,
    String productId,
  ) async {
    final response = await _networkService.get(
      ApiRoute.storeProduct(store, productId),
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid product response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Product could not be retrieved.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Product could not be retrieved.",
      );
    }

    final currencyRaw = data["currency"];
    final currency = currencyRaw is Map
        ? StoreCurrencyDto.fromJson(Map<String, dynamic>.from(currencyRaw))
        : const StoreCurrencyDto(code: "", symbol: "");

    final productRaw = data["product"];
    if (productRaw is! Map) {
      throw ApiFailure("Product not found.");
    }

    return StoreProductDetailResult(
      currency: currency,
      product: StoreProductDetailDto.fromJson(
        Map<String, dynamic>.from(productRaw),
      ),
    );
  }

  @override
  Future<StoreCartData> getCart() async {
    final response = await _networkService.get(ApiRoute.storeCart);
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid cart response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Cart could not be retrieved.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Cart could not be retrieved.",
      );
    }
    return StoreCartData.fromJson(data);
  }

  @override
  Future<StoreCartAddResult> addCartItem({
    required String variantUid,
    required int quantity,
  }) async {
    final response = await _networkService.post(
      ApiRoute.storeCartItems,
      data: {
        "variant_uid": variantUid.trim(),
        "quantity": quantity.clamp(1, 1000),
      },
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid cart response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not add item to cart.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not add item to cart.",
      );
    }
    return StoreCartAddResult.fromJson(data);
  }

  @override
  Future<StoreCartUpdateResult> updateCartItem(
    String itemUid, {
    int? quantity,
    bool? isSelected,
  }) async {
    final body = <String, dynamic>{};
    if (quantity != null) body["quantity"] = quantity.clamp(1, 1000);
    if (isSelected != null) body["is_selected"] = isSelected;
    if (body.isEmpty) {
      throw ApiFailure("Nothing to update.");
    }

    final response = await _networkService.patch(
      ApiRoute.storeCartItem(itemUid.trim()),
      data: body,
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid cart response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not update cart item.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not update cart item.",
      );
    }
    return StoreCartUpdateResult.fromJson(data);
  }

  @override
  Future<void> removeCartItem(String itemUid) async {
    final response = await _networkService.delete(
      ApiRoute.storeCartItem(itemUid.trim()),
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) return;
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not remove cart item.",
      );
    }
  }

  @override
  Future<StoreCheckoutQuote> quoteCheckout(
    String store, {
    String? promoCode,
    String? addressUid,
  }) async {
    final body = <String, dynamic>{};
    final promo = promoCode?.trim();
    if (promo != null && promo.isNotEmpty) {
      body["promo_code"] = promo.length > 40 ? promo.substring(0, 40) : promo;
    }
    final address = addressUid?.trim();
    if (address != null && address.isNotEmpty) {
      body["address_uid"] = address;
    }

    final response = await _networkService.post(
      ApiRoute.storeCheckoutQuote(store),
      data: body,
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid checkout quote response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not load checkout quote.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not load checkout quote.",
      );
    }
    return StoreCheckoutQuote.fromJson(data);
  }

  @override
  Future<StoreCheckoutResult> checkout(
    String store, {
    String? promoCode,
    String? addressUid,
  }) async {
    final body = <String, dynamic>{};
    final promo = promoCode?.trim();
    if (promo != null && promo.isNotEmpty) {
      body["promo_code"] = promo.length > 40 ? promo.substring(0, 40) : promo;
    }
    final address = addressUid?.trim();
    if (address != null && address.isNotEmpty) {
      body["address_uid"] = address;
    }

    final response = await _networkService.post(
      ApiRoute.storeCheckout(store),
      data: body,
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid checkout response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not start checkout.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not start checkout.",
      );
    }
    return StoreCheckoutResult.fromJson(data);
  }

  @override
  Future<void> verifyPayment({required String reference}) async {
    final ref = reference.trim();
    if (ref.isEmpty) {
      throw ApiFailure("Missing payment reference.");
    }
    await _networkService.get(ApiRoute.paymentVerify(ref));
  }

  @override
  Future<List<StoreCheckoutAddress>> getAddresses() async {
    final response = await _networkService.get(ApiRoute.addresses);
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid addresses response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not load addresses.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not load addresses.",
      );
    }
    final list = data["addresses"];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(
          (e) => StoreCheckoutAddress.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false);
  }

  @override
  Future<StoreCheckoutAddress> addAddress({
    required String buildingNumber,
    required String street,
    required String countryIso,
    required String state,
    required String city,
    required String phone,
    String? postalCode,
    bool isDefault = true,
  }) async {
    final response = await _networkService.post(
      ApiRoute.addresses,
      data: _addressBody(
        buildingNumber: buildingNumber,
        street: street,
        countryIso: countryIso,
        state: state,
        city: city,
        phone: phone,
        postalCode: postalCode,
        isDefault: isDefault,
      ),
    );
    return _parseAddressResponse(
      response.data,
      fallbackMessage: "Could not save address.",
    );
  }

  @override
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
  }) async {
    final response = await _networkService.put(
      ApiRoute.address(addressUid),
      data: _addressBody(
        buildingNumber: buildingNumber,
        street: street,
        countryIso: countryIso,
        state: state,
        city: city,
        phone: phone,
        postalCode: postalCode,
        isDefault: isDefault,
      ),
    );
    return _parseAddressResponse(
      response.data,
      fallbackMessage: "Could not update address.",
    );
  }

  @override
  Future<void> deleteAddress(String addressUid) async {
    final response = await _networkService.delete(ApiRoute.address(addressUid));
    final root = response.data;
    if (root is! Map<String, dynamic>) return;
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not delete address.",
      );
    }
  }

  Map<String, dynamic> _addressBody({
    required String buildingNumber,
    required String street,
    required String countryIso,
    required String state,
    required String city,
    required String phone,
    String? postalCode,
    required bool isDefault,
  }) {
    final body = <String, dynamic>{
      "building_number": buildingNumber.trim(),
      "street": street.trim(),
      "country_iso": countryIso.trim().toUpperCase(),
      "state": state.trim(),
      "city": city.trim(),
      "phone": phone.trim(),
      "is_default": isDefault,
    };
    final postal = postalCode?.trim();
    if (postal != null && postal.isNotEmpty) {
      body["postal_code"] = postal;
    }
    return body;
  }

  StoreCheckoutAddress _parseAddressResponse(
    dynamic responseData, {
    required String fallbackMessage,
  }) {
    if (responseData is! Map<String, dynamic>) {
      throw ApiFailure("Invalid address response");
    }
    final status = responseData["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        responseData["message"]?.toString() ?? fallbackMessage,
      );
    }
    final data = responseData["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        responseData["message"]?.toString() ?? fallbackMessage,
      );
    }
    final addressRaw = data["address"];
    if (addressRaw is! Map) {
      throw ApiFailure(
        responseData["message"]?.toString() ?? fallbackMessage,
      );
    }
    return StoreCheckoutAddress.fromJson(
      Map<String, dynamic>.from(addressRaw),
    );
  }

  Map<String, dynamic> _productParams({
    String? search,
    String? categoryUid,
    String? cursor,
    required int perPage,
  }) {
    final params = <String, dynamic>{
      "per_page": perPage.clamp(1, 50).toString(),
    };
    final q = search?.trim();
    if (q != null && q.isNotEmpty) params["search"] = q;
    final category = categoryUid?.trim();
    if (category != null && category.isNotEmpty) {
      params["category"] = category;
    }
    if (cursor != null && cursor.isNotEmpty) params["cursor"] = cursor;
    return params;
  }
}

final storeRepositoryProvider = Provider<StoreRepo>((ref) {
  return StoreRepoImpl(networkService: ref.read(networkServiceProvider));
});
