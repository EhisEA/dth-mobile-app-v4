import "package:dth_v4/core/extension/view_model_state.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Paid store orders — newest first, grouped by API `placed_at` label.
class OrdersState extends ChangeNotifier {
  OrdersState(this._repo);

  final OrdersRepo _repo;

  List<Order> _orders = const [];
  String? _nextCursor;
  ViewModelState _loadState = const ViewModelState.idle();
  bool _loadingMore = false;
  bool _hasLoaded = false;
  int _generation = 0;

  /// True while the latest [fetch] runs. A quiet fetch never sets busy, so
  /// [loadMore] checks this to avoid paging from a cursor about to be replaced.
  bool _fetching = false;

  List<Order> get orders => _orders;
  ViewModelState get loadState => _loadState;
  bool get loadingMore => _loadingMore;
  bool get hasLoaded => _hasLoaded;
  bool get hasMore => _nextCursor != null;

  List<OrderDateGroup> get groups {
    final map = <String, List<Order>>{};
    final labels = <String>[];
    for (final order in _orders) {
      final label = order.placedAt.trim().isEmpty
          ? "Orders"
          : order.placedAt.trim();
      if (!map.containsKey(label)) {
        labels.add(label);
        map[label] = [];
      }
      map[label]!.add(order);
    }
    return [
      for (final label in labels)
        OrderDateGroup(label: label, orders: map[label]!),
    ];
  }

  Future<void> fetch({bool quiet = false}) async {
    final generation = ++_generation;
    _fetching = true;
    if (!quiet) {
      _loadState = const ViewModelState.busy();
      notifyListeners();
    }
    try {
      final page = await _repo.getOrders();
      if (generation != _generation) return;
      _orders = page.orders.items;
      _nextCursor = page.orders.nextCursor;
      _hasLoaded = true;
      _loadState = const ViewModelState.idle();
      notifyListeners();
    } on ApiFailure catch (e) {
      if (generation != _generation) return;
      if (!quiet || !_hasLoaded) {
        _loadState = ViewModelState.error(e);
      }
      notifyListeners();
    } catch (e) {
      if (generation != _generation) return;
      if (!quiet || !_hasLoaded) {
        _loadState = ViewModelState.error(ApiFailure(e.toString()));
      }
      notifyListeners();
    } finally {
      if (generation == _generation) _fetching = false;
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    final generation = _generation;
    if (cursor == null || _loadingMore || _fetching || _loadState.isBusy) {
      return;
    }
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.getOrders(cursor: cursor);
      if (generation != _generation || cursor != _nextCursor) return;
      _orders = [..._orders, ...page.orders.items];
      _nextCursor = page.orders.nextCursor;
    } on ApiFailure {
      // Keep existing list; user can pull to refresh.
    } catch (_) {
      // Keep existing list.
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void clear() {
    _generation++;
    _fetching = false;
    _orders = const [];
    _nextCursor = null;
    _loadingMore = false;
    _hasLoaded = false;
    _loadState = const ViewModelState.idle();
    notifyListeners();
  }
}

final ordersStateProvider = ChangeNotifierProvider<OrdersState>((ref) {
  return OrdersState(ref.read(ordersRepositoryProvider));
});
