import "package:dth_v4/data/models/paginated_result.dart";
import "package:dth_v4/data/models/store/store_checkout_quote_model.dart";
import "package:dth_v4/data/models/store/store_kind.dart";
import "package:dth_v4/data/models/store/store_product_dto.dart";
import "package:flutter/foundation.dart";

enum OrderStatus { inProgress, delivered, cancelled, unknown }

@immutable
class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.vendor,
    this.imageUrl,
    this.size,
    this.color,
  });

  final String name;
  final String? vendor;
  final String? imageUrl;
  final String? size;
  final String? color;
  final int quantity;
  final int unitPrice;
  final int lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: (json["name"] ?? "").toString(),
      vendor: _nullableString(json["vendor"]),
      imageUrl: _nullableString(json["image_url"]),
      size: _nullableString(json["size"]),
      color: _nullableString(json["color"]),
      quantity: _parseInt(json["quantity"]) ?? 0,
      unitPrice: _parseMoney(json["unit_price"]) ?? 0,
      lineTotal: _parseMoney(json["line_total"]) ?? 0,
    );
  }
}

@immutable
class OrderTotal {
  const OrderTotal({required this.label, required this.value});

  final String label;
  final int value;

  factory OrderTotal.fromJson(Map<String, dynamic> json) {
    return OrderTotal(
      label: (json["label"] ?? "Total").toString(),
      value: _parseMoney(json["value"]) ?? 0,
    );
  }
}

@immutable
class OrderTimelineStep {
  const OrderTimelineStep({
    required this.status,
    required this.title,
    required this.description,
    this.at,
    this.timeAgo,
  });

  final String status;
  final String title;
  final String description;
  final DateTime? at;
  final String? timeAgo;

  factory OrderTimelineStep.fromJson(Map<String, dynamic> json) {
    final atRaw = (json["at"] ?? "").toString();
    return OrderTimelineStep(
      status: (json["status"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      at: DateTime.tryParse(atRaw)?.toLocal(),
      timeAgo: _nullableString(json["time_ago"]),
    );
  }
}

@immutable
class OrderSummaryLine {
  const OrderSummaryLine({
    required this.label,
    required this.value,
    this.key,
    this.type,
  });

  final String? key;
  final String label;
  final String value;
  final String? type;

  factory OrderSummaryLine.fromJson(Map<String, dynamic> json) {
    return OrderSummaryLine(
      key: _nullableString(json["key"]),
      label: (json["label"] ?? "").toString(),
      value: (json["value"] ?? "").toString(),
      type: _nullableString(json["type"]),
    );
  }
}

@immutable
class Order {
  const Order({
    required this.uid,
    required this.number,
    required this.storeType,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.placedAt,
    required this.currency,
    required this.total,
    required this.itemsCount,
    required this.items,
    required this.canTrack,
    required this.canReorder,
    this.pickupCode,
    this.deliveringTo,
    this.summary = const [],
    this.promoCode,
    this.address,
    this.cancelReason,
    this.timeline = const [],
  });

  final String uid;
  final String number;
  final String storeType;
  final String title;
  final OrderStatus status;
  final String statusLabel;

  /// Server-formatted day label for grouping (e.g. "Today, October 14th, 2026").
  final String placedAt;
  final StoreCurrencyDto currency;
  final OrderTotal total;
  final int itemsCount;
  final List<OrderItem> items;
  final String? pickupCode;
  final String? deliveringTo;
  final bool canTrack;
  final bool canReorder;
  final List<OrderSummaryLine> summary;
  final String? promoCode;
  final StoreCheckoutAddress? address;
  final String? cancelReason;
  final List<OrderTimelineStep> timeline;

  bool get isInProgress => status == OrderStatus.inProgress;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;

  String get currencySymbol =>
      currency.symbol.isNotEmpty ? currency.symbol : "₦";

  factory Order.fromJson(Map<String, dynamic> json) {
    final currencyRaw = json["currency"];
    final totalRaw = json["total"];
    final itemsRaw = json["items"];
    final summaryRaw = json["summary"];
    final timelineRaw = json["timeline"];
    final addressRaw = json["address"];
    final placedRaw = (json["placed_at"] ?? "").toString().trim();
    final labelRaw = (json["status_label"] ?? "").toString().trim();

    return Order(
      uid: (json["uid"] ?? "").toString(),
      number: (json["number"] ?? "").toString(),
      storeType: (json["store_type"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      status: _parseStatus(json["status"], json["status_label"]),
      statusLabel: labelRaw.isEmpty
          ? _defaultStatusLabel(json["status"])
          : labelRaw,
      placedAt: placedRaw,
      currency: currencyRaw is Map
          ? StoreCurrencyDto.fromJson(Map<String, dynamic>.from(currencyRaw))
          : const StoreCurrencyDto(code: "", symbol: ""),
      total: totalRaw is Map
          ? OrderTotal.fromJson(Map<String, dynamic>.from(totalRaw))
          : const OrderTotal(label: "Total", value: 0),
      itemsCount: _parseInt(json["items_count"]) ?? 0,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList(growable: false)
          : const [],
      pickupCode: _nullableString(json["pickup_code"]),
      deliveringTo: _nullableString(json["delivering_to"]),
      canTrack: json["can_track"] == true,
      canReorder: json["can_reorder"] == true,
      summary: summaryRaw is List
          ? summaryRaw
                .whereType<Map>()
                .map(
                  (e) =>
                      OrderSummaryLine.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
      promoCode: _nullableString(json["promo_code"]),
      address: addressRaw is Map
          ? StoreCheckoutAddress.fromJson(Map<String, dynamic>.from(addressRaw))
          : null,
      cancelReason: _nullableString(json["cancel_reason"]),
      timeline: timelineRaw is List
          ? timelineRaw
                .whereType<Map>()
                .map(
                  (e) =>
                      OrderTimelineStep.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

@immutable
class OrderReorderSkipped {
  const OrderReorderSkipped({required this.name, required this.reason});

  final String name;
  final String reason;

  factory OrderReorderSkipped.fromJson(Map<String, dynamic> json) {
    return OrderReorderSkipped(
      name: (json["name"] ?? "").toString(),
      reason: (json["reason"] ?? "").toString(),
    );
  }
}

@immutable
class OrderReorderResult {
  const OrderReorderResult({
    required this.added,
    required this.skipped,
    required this.storeType,
    required this.count,
  });

  final int added;
  final List<OrderReorderSkipped> skipped;
  final String storeType;
  final int count;

  StoreKind get kind => storeType.toLowerCase() == "event"
      ? StoreKind.liveEvent
      : StoreKind.merch;

  factory OrderReorderResult.fromJson(Map<String, dynamic> json) {
    final skippedRaw = json["skipped"];
    return OrderReorderResult(
      added: _parseInt(json["added"]) ?? 0,
      skipped: skippedRaw is List
          ? skippedRaw
                .whereType<Map>()
                .map(
                  (e) => OrderReorderSkipped.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
      storeType: (json["store_type"] ?? "").toString(),
      count: _parseInt(json["count"]) ?? 0,
    );
  }
}

@immutable
class OrdersPage {
  const OrdersPage({required this.orders});

  final PaginatedResult<Order> orders;
}

@immutable
class OrderDateGroup {
  const OrderDateGroup({required this.label, required this.orders});

  final String label;
  final List<Order> orders;
}

OrderStatus _parseStatus(dynamic status, dynamic statusLabel) {
  final raw = [
    status?.toString() ?? "",
    statusLabel?.toString() ?? "",
  ].join(" ").toLowerCase();
  if (raw.contains("cancel")) return OrderStatus.cancelled;
  if (raw.contains("deliver") || raw.contains("completed")) {
    return OrderStatus.delivered;
  }
  if (raw.contains("progress") ||
      raw.contains("processing") ||
      raw.contains("transit") ||
      raw.contains("pending_payment") ||
      raw.contains("placed")) {
    return OrderStatus.inProgress;
  }
  return OrderStatus.unknown;
}

String _defaultStatusLabel(dynamic status) {
  final raw = (status ?? "").toString().toLowerCase();
  if (raw.contains("cancel")) return "Cancelled";
  if (raw.contains("deliver") || raw.contains("completed")) {
    return "Delivered";
  }
  if (raw.contains("progress") ||
      raw.contains("processing") ||
      raw.contains("transit") ||
      raw.contains("pending_payment")) {
    return "In Progress";
  }
  return (status ?? "").toString();
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

int? _parseMoney(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  final parsed = double.tryParse(value.toString().trim());
  if (parsed == null) return null;
  return parsed.round();
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString().trim());
}
