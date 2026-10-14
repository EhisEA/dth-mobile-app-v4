import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class OrdersRepoImpl implements OrdersRepo {
  OrdersRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<OrdersPage> getOrders({
    String? store,
    String? cursor,
    int perPage = 15,
  }) async {
    final params = <String, dynamic>{
      "per_page": perPage.clamp(1, 50).toString(),
    };
    final storeFilter = store?.trim();
    if (storeFilter != null && storeFilter.isNotEmpty) {
      params["store"] = storeFilter;
    }
    if (cursor != null && cursor.isNotEmpty) {
      params["cursor"] = cursor;
    }

    final response = await _networkService.get(
      ApiRoute.storeOrders,
      queryParams: params,
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid orders response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Orders could not be retrieved.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Orders could not be retrieved.",
      );
    }

    final ordersOuter = data["orders"];
    if (ordersOuter is! Map<String, dynamic>) {
      return const OrdersPage(
        orders: PaginatedResult(items: [], nextCursor: null),
      );
    }

    final list = ordersOuter["data"];
    final items = list is List<dynamic>
        ? list
              .whereType<Map>()
              .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
              .where((o) => o.uid.isNotEmpty)
              .toList(growable: false)
        : const <Order>[];

    final cursorRaw = ordersOuter["next_cursor"];
    final nextCursor = cursorRaw is String && cursorRaw.isNotEmpty
        ? cursorRaw
        : null;

    return OrdersPage(
      orders: PaginatedResult(items: items, nextCursor: nextCursor),
    );
  }

  @override
  Future<Order> getOrder(String orderUid) async {
    final uid = orderUid.trim();
    if (uid.isEmpty) {
      throw ApiFailure("Missing order id.");
    }

    final response = await _networkService.get(ApiRoute.storeOrder(uid));
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid order response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Order could not be retrieved.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Order could not be retrieved.",
      );
    }
    final orderRaw = data["order"];
    if (orderRaw is! Map) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Order could not be retrieved.",
      );
    }
    final order = Order.fromJson(Map<String, dynamic>.from(orderRaw));
    if (order.uid.isEmpty) {
      throw ApiFailure("Order could not be retrieved.");
    }
    return order;
  }

  @override
  Future<OrderReorderResult> reorder(String orderUid) async {
    final uid = orderUid.trim();
    if (uid.isEmpty) {
      throw ApiFailure("Missing order id.");
    }

    final response = await _networkService.post(ApiRoute.storeOrderReorder(uid));
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid reorder response");
    }
    final status = root["status"]?.toString();
    if (status == "failed") {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not reorder these items.",
      );
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not reorder these items.",
      );
    }
    return OrderReorderResult.fromJson(data);
  }
}

final ordersRepositoryProvider = Provider<OrdersRepo>((ref) {
  return OrdersRepoImpl(networkService: ref.read(networkServiceProvider));
});
