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
    if (!quiet) {
      _loadState = const ViewModelState.busy();
      notifyListeners();
    }
    try {
      final page = await _repo.getOrders();
      _orders = page.orders.items;
      _nextCursor = page.orders.nextCursor;
      _hasLoaded = true;
      _loadState = const ViewModelState.idle();
      notifyListeners();
    } on ApiFailure catch (e) {
      if (!quiet || !_hasLoaded) {
        _loadState = ViewModelState.error(e);
      }
      notifyListeners();
    } catch (e) {
      if (!quiet || !_hasLoaded) {
        _loadState = ViewModelState.error(ApiFailure(e.toString()));
      }
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore || _loadState.isBusy) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.getOrders(cursor: cursor);
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
}

final ordersStateProvider = ChangeNotifierProvider<OrdersState>((ref) {
  return OrdersState(ref.read(ordersRepositoryProvider));
});
