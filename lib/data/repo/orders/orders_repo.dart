import "package:dth_v4/data/models/orders/orders.dart";

abstract class OrdersRepo {
  /// `GET /api/store/orders` — paid orders, newest first.
  ///
  /// Pass [store] as `event` or `merch` to filter one store; omit for both.
  Future<OrdersPage> getOrders({
    String? store,
    String? cursor,
    int perPage = 15,
  });

  /// `GET /api/store/orders/{order}` — detail with summary, address, timeline.
  Future<Order> getOrder(String orderUid);

  /// `POST /api/store/orders/{order}/reorder` — add order items to cart again.
  Future<OrderReorderResult> reorder(String orderUid);
}
