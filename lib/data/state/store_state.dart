import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Shared cache + network access for store fronts (`merch` / `event`).
///
/// Catalog screens read warm [cached] / [cachedCategories] / [cachedProducts]
/// to skip loading flashes; subsequent visits reuse the first products page.
class StoreState extends ChangeNotifier {
  StoreState(this._repo);

  final StoreRepo _repo;

  final Map<String, StoreInfoModel> _stores = {};
  final Map<String, List<StoreCategoryDto>> _categories = {};
  final Map<String, StoreCurrencyDto> _currency = {};
  final Map<String, StoreProductsPage> _productPages = {};
  final Map<String, StoreProductDetailResult> _productDetails = {};
  final Map<String, Future<StoreInfoModel>> _inFlight = {};
  final Map<String, Future<List<StoreCategoryDto>>> _categoriesInFlight = {};
  final Map<String, Future<StoreProductsPage>> _productsInFlight = {};
  final Map<String, Future<StoreProductDetailResult>> _productDetailInFlight =
      {};

  StoreInfoModel? cached(String storeId) => _stores[storeId];

  List<StoreCategoryDto>? cachedCategories(String storeId) =>
      _categories[storeId];

  StoreCurrencyDto? currency(String storeId) => _currency[storeId];

  /// First-page products for the given filters (no cursor).
  StoreProductsPage? cachedProducts(
    String storeId, {
    String? search,
    String? categoryUid,
  }) {
    return _productPages[_productsKey(
      storeId,
      search: search,
      categoryUid: categoryUid,
    )];
  }

  StoreProductDetailResult? cachedProductDetail(
    String storeId,
    String productId,
  ) {
    return _productDetails[_detailKey(storeId, productId)];
  }

  bool get isEventStoreOpen => cached("event")?.isOpen == true;

  /// Prefetch enabled store fronts + categories from the latest modules payload.
  Future<void> prefetchFromModules(AppModulesModel? modules) async {
    if (modules == null) return;
    final jobs = <Future<void>>[];
    if (modules.merchStore) {
      jobs.add(fetch("merch").then((_) {}, onError: (_) {}));
      jobs.add(fetchCategories("merch").then((_) {}, onError: (_) {}));
    }
    if (modules.eventStore) {
      jobs.add(fetch("event").then((_) {}, onError: (_) {}));
      jobs.add(fetchCategories("event").then((_) {}, onError: (_) {}));
    }
    if (jobs.isEmpty) return;
    await Future.wait(jobs);
  }

  /// Returns cached data immediately when present; otherwise hits the network.
  /// Concurrent callers for the same [storeId] share one request.
  Future<StoreInfoModel> fetch(String storeId, {bool forceRefresh = false}) {
    final id = storeId.trim();
    if (!forceRefresh) {
      final hit = _stores[id];
      if (hit != null) return Future.value(hit);
      final pending = _inFlight[id];
      if (pending != null) return pending;
    }

    final future = _load(id);
    _inFlight[id] = future;
    return future.whenComplete(() {
      _inFlight.remove(id);
    });
  }

  Future<StoreInfoModel> _load(String storeId) async {
    final store = await _repo.getStore(storeId);
    _stores[storeId] = store;
    notifyListeners();
    return store;
  }

  Future<List<StoreCategoryDto>> fetchCategories(
    String storeId, {
    bool forceRefresh = false,
  }) {
    final id = storeId.trim();
    if (!forceRefresh) {
      final hit = _categories[id];
      if (hit != null) return Future.value(hit);
      final pending = _categoriesInFlight[id];
      if (pending != null) return pending;
    }

    final future = _loadCategories(id);
    _categoriesInFlight[id] = future;
    return future.whenComplete(() {
      _categoriesInFlight.remove(id);
    });
  }

  Future<List<StoreCategoryDto>> _loadCategories(String storeId) async {
    final list = await _repo.getCategories(storeId);
    _categories[storeId] = list;
    notifyListeners();
    return list;
  }

  /// Catalog products for [storeId] (`event` or `merch`).
  ///
  /// First pages (no [cursor]) are cached per search/category so re-entry and
  /// category re-taps can hydrate instantly. Pass [forceRefresh] to bypass.
  Future<StoreProductsPage> fetchProducts(
    String storeId, {
    String? search,
    String? categoryUid,
    String? cursor,
    int perPage = 20,
    bool forceRefresh = false,
  }) async {
    final id = storeId.trim();
    final isFirstPage = cursor == null || cursor.isEmpty;
    final key = _productsKey(id, search: search, categoryUid: categoryUid);

    if (isFirstPage && !forceRefresh) {
      final hit = _productPages[key];
      if (hit != null) return hit;
      final pending = _productsInFlight[key];
      if (pending != null) return pending;
    }

    Future<StoreProductsPage> load() async {
      final page = await _repo.getProducts(
        id,
        search: search,
        categoryUid: categoryUid,
        cursor: cursor,
        perPage: perPage,
      );
      if (page.currency.code.isNotEmpty || page.currency.symbol.isNotEmpty) {
        _currency[id] = page.currency;
      }
      if (isFirstPage) {
        _productPages[key] = page;
      }
      notifyListeners();
      return page;
    }

    if (!isFirstPage) return load();

    final future = load();
    _productsInFlight[key] = future;
    return future.whenComplete(() {
      _productsInFlight.remove(key);
    });
  }

  /// Single product detail (images, colors, variants). Cached by store+uid.
  Future<StoreProductDetailResult> fetchProduct(
    String storeId,
    String productId, {
    bool forceRefresh = false,
  }) {
    final id = storeId.trim();
    final pid = productId.trim();
    final key = _detailKey(id, pid);

    if (!forceRefresh) {
      final hit = _productDetails[key];
      if (hit != null) return Future.value(hit);
    }
    // Reuse in-flight even on forceRefresh to avoid duplicate GETs.
    final pending = _productDetailInFlight[key];
    if (pending != null) return pending;

    final future = _loadProduct(id, pid, key);
    _productDetailInFlight[key] = future;
    return future.whenComplete(() {
      _productDetailInFlight.remove(key);
    });
  }

  Future<StoreProductDetailResult> _loadProduct(
    String storeId,
    String productId,
    String key,
  ) async {
    final result = await _repo.getProduct(storeId, productId);
    if (result.currency.code.isNotEmpty || result.currency.symbol.isNotEmpty) {
      _currency[storeId] = result.currency;
    }
    _productDetails[key] = result;
    notifyListeners();
    return result;
  }

  String _productsKey(String storeId, {String? search, String? categoryUid}) {
    final q = search?.trim() ?? "";
    final c = categoryUid?.trim() ?? "";
    return "$storeId|$q|$c";
  }

  String _detailKey(String storeId, String productId) =>
      "${storeId.trim()}|${productId.trim()}";

  void clear() {
    _stores.clear();
    _categories.clear();
    _currency.clear();
    _productPages.clear();
    _productDetails.clear();
    _inFlight.clear();
    _categoriesInFlight.clear();
    _productsInFlight.clear();
    _productDetailInFlight.clear();
    notifyListeners();
  }
}

final storeStateProvider = ChangeNotifierProvider<StoreState>((ref) {
  return StoreState(ref.read(storeRepositoryProvider));
});
