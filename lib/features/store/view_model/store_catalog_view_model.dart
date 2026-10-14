import "dart:async";

import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCatalogViewModel extends ChangeNotifier {
  StoreCatalogViewModel({required this.kind, required StoreState storeState})
    : _storeState = storeState,
      _selectedCategoryId = StoreCategory.allId {
    final cached = _storeState.cached(kind.apiStoreId);
    if (cached != null) {
      _store = cached;
      _loadState = const ViewModelState.idle();
    }
    final cachedCategories = _storeState.cachedCategories(kind.apiStoreId);
    if (cachedCategories != null) {
      _applyCategories(cachedCategories);
    }
    final currency = _storeState.currency(kind.apiStoreId);
    if (currency != null) {
      _currencyCode = currency.code;
      if (currency.symbol.isNotEmpty) _currencySymbol = currency.symbol;
    }
    _hydrateProductsFromCache();
  }

  static const _searchDebounce = Duration(milliseconds: 400);

  final StoreKind kind;
  final StoreState _storeState;

  List<StoreCategory> _categories = const [
    StoreCategory(id: StoreCategory.allId, label: "All"),
  ];
  String _selectedCategoryId;
  String _searchQuery = "";
  StoreInfoModel? _store;
  ViewModelState _loadState = const ViewModelState.busy();

  List<StoreProduct> _products = const [];
  String? _nextCursor;
  String _currencySymbol = "₦";
  String _currencyCode = "";
  bool _productsBusy = false;
  bool _loadingMore = false;
  bool _hasLoadedProducts = false;
  int _productsRequestId = 0;
  Timer? _searchDebounceTimer;

  List<StoreCategory> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  StoreInfoModel? get store => _store;
  ViewModelState get loadState => _loadState;
  List<StoreProduct> get products => _products;
  bool get productsBusy => _productsBusy;
  bool get loadingMore => _loadingMore;
  bool get hasMoreProducts => _nextCursor != null;
  String get currencySymbol => _currencySymbol;

  /// True until the first products request for the current filters settles.
  bool get showProductsSkeleton =>
      !_hasLoadedProducts || (_productsBusy && _products.isEmpty);

  bool get hasActiveSearch => _searchQuery.trim().isNotEmpty;

  String get displayTitle {
    final store = _store;
    if (store == null) {
      return kind == StoreKind.merch ? "Shopping Complex" : "Live Event Stores";
    }
    final eventName = store.event?.name.trim();
    if (eventName != null && eventName.isNotEmpty) return eventName;
    return store.name;
  }

  String? get _activeCategoryUid =>
      _selectedCategoryId == StoreCategory.allId ? null : _selectedCategoryId;

  String? get _activeSearch {
    final q = _searchQuery.trim();
    return q.isEmpty ? null : q;
  }

  void _applyCategories(List<StoreCategoryDto> remote) {
    final allLabel = kind == StoreKind.merch ? "All Merchs" : "All";
    _categories = [
      StoreCategory(id: StoreCategory.allId, label: allLabel),
      for (final c in remote) StoreCategory(id: c.uid, label: c.name),
    ];
    if (!_categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = StoreCategory.allId;
    }
  }

  bool _hydrateProductsFromCache() {
    final page = _storeState.cachedProducts(
      kind.apiStoreId,
      search: _activeSearch,
      categoryUid: _activeCategoryUid,
    );
    if (page == null) return false;
    _applyProductsPage(page, reset: true);
    _hasLoadedProducts = true;
    _productsBusy = false;
    return true;
  }

  void _applyProductsPage(StoreProductsPage page, {required bool reset}) {
    _currencyCode = page.currency.code;
    if (page.currency.symbol.isNotEmpty) {
      _currencySymbol = page.currency.symbol;
    }

    final mapped = page.products.items
        .map(
          (dto) => StoreProduct.fromDto(
            dto,
            kind: kind,
            currencyCode: _currencyCode,
            currencySymbol: _currencySymbol,
          ),
        )
        .toList(growable: false);

    _products = reset ? mapped : [..._products, ...mapped];
    _nextCursor = page.products.nextCursor;
  }

  /// Prefer warm cache (no shimmer). Falls back to a loading fetch.
  Future<void> loadStore({bool forceRefresh = false}) async {
    final warm = _storeState.cached(kind.apiStoreId);
    final warmCategories = _storeState.cachedCategories(kind.apiStoreId);

    if (!forceRefresh && (warm != null || _store != null)) {
      _store ??= warm;
      if (warmCategories != null) _applyCategories(warmCategories);
      _loadState = const ViewModelState.idle();

      final storeOpen = _store?.isOpen == true;
      if (storeOpen) {
        final hadCache = _hydrateProductsFromCache();
        if (!hadCache && _products.isEmpty) {
          _productsBusy = true;
          _hasLoadedProducts = false;
        }
      }
      notifyListeners();
      unawaited(
        _refreshQuietly(
          forceProducts: forceRefresh || !_hasLoadedProducts,
        ),
      );
      return;
    }

    _loadState = const ViewModelState.busy();
    notifyListeners();
    try {
      await _fetchStoreAndCategories(forceRefresh: forceRefresh);
      if (_store?.isOpen == true) {
        await _fetchProducts(reset: true, forceRefresh: forceRefresh);
      }
      _loadState = const ViewModelState.idle();
      notifyListeners();
    } on ApiFailure catch (e) {
      _loadState = ViewModelState.error(e);
      notifyListeners();
    } catch (e) {
      _loadState = ViewModelState.error(ApiFailure(e.toString()));
      notifyListeners();
    }
  }

  /// Pull-to-refresh: re-fetch without flipping to the shimmer busy state.
  Future<void> refresh() => _refreshQuietly(forceProducts: true);

  Future<void> _refreshQuietly({bool forceProducts = false}) async {
    try {
      await _fetchStoreAndCategories(forceRefresh: true);
      if (_store?.isOpen == true) {
        await _fetchProducts(reset: true, forceRefresh: forceProducts);
      } else {
        _products = const [];
        _nextCursor = null;
        _hasLoadedProducts = true;
        _productsBusy = false;
      }
      _loadState = const ViewModelState.idle();
      notifyListeners();
    } catch (_) {
      // Keep showing the last good payload.
      if (_productsBusy) {
        _productsBusy = false;
        _hasLoadedProducts = true;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchStoreAndCategories({required bool forceRefresh}) async {
    final storeId = kind.apiStoreId;
    final results = await Future.wait([
      _storeState.fetch(storeId, forceRefresh: forceRefresh),
      _storeState.fetchCategories(storeId, forceRefresh: forceRefresh),
    ]);
    _store = results[0] as StoreInfoModel;
    _applyCategories(results[1] as List<StoreCategoryDto>);
  }

  Future<void> _fetchProducts({
    required bool reset,
    bool forceRefresh = false,
  }) async {
    final requestId = ++_productsRequestId;
    if (reset) {
      // Only flash the skeleton when we have nothing to show yet.
      if (_products.isEmpty) {
        _productsBusy = true;
        _hasLoadedProducts = false;
        notifyListeners();
      }
      _nextCursor = null;
    }

    try {
      final page = await _storeState.fetchProducts(
        kind.apiStoreId,
        search: _activeSearch,
        categoryUid: _activeCategoryUid,
        cursor: reset ? null : _nextCursor,
        forceRefresh: forceRefresh && reset,
      );
      if (requestId != _productsRequestId) return;

      _applyProductsPage(page, reset: reset);
      _hasLoadedProducts = true;
    } finally {
      if (requestId == _productsRequestId) {
        _productsBusy = false;
      }
    }
  }

  Future<void> loadMoreProducts() async {
    if (!hasMoreProducts || _loadingMore || _productsBusy) return;
    _loadingMore = true;
    notifyListeners();
    try {
      await _fetchProducts(reset: false);
    } on ApiFailure {
      // Keep current list; user can scroll again to retry.
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _reloadProducts({bool forceRefresh = false}) async {
    // Prefer cache for the new filter set; only network when missing.
    final hadCache = _hydrateProductsFromCache();
    if (hadCache) {
      notifyListeners();
      // Soft refresh in background so filters stay snappy.
      unawaited(
        _fetchProducts(reset: true, forceRefresh: forceRefresh).then((_) {
          notifyListeners();
        }),
      );
      return;
    }

    _products = const [];
    _nextCursor = null;
    _hasLoadedProducts = false;
    _productsBusy = true;
    notifyListeners();

    try {
      await _fetchProducts(reset: true, forceRefresh: forceRefresh);
    } on ApiFailure {
      _hasLoadedProducts = true;
    }
    notifyListeners();
  }

  void selectCategory(String id) {
    if (_selectedCategoryId == id) return;
    _selectedCategoryId = id;
    notifyListeners();
    unawaited(_reloadProducts());
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      unawaited(_reloadProducts());
    });
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchDebounceTimer?.cancel();
    _searchQuery = "";
    notifyListeners();
    unawaited(_reloadProducts());
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}

final storeCatalogProvider = ChangeNotifierProvider.autoDispose
    .family<StoreCatalogViewModel, StoreKind>((ref, kind) {
      final vm = StoreCatalogViewModel(
        kind: kind,
        storeState: ref.read(storeStateProvider),
      );
      Future.microtask(() => vm.loadStore());
      return vm;
    });
