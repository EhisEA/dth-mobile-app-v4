class StoreCurrency {
  const StoreCurrency({required this.code, required this.symbol});

  final String code;
  final String symbol;

  factory StoreCurrency.fromJson(Map<String, dynamic> json) {
    return StoreCurrency(
      code: (json["code"] ?? "NGN").toString(),
      symbol: (json["symbol"] ?? "₦").toString(),
    );
  }

  Map<String, dynamic> toJson() => {"code": code, "symbol": symbol};
}

class StoreEventSummary {
  const StoreEventSummary({required this.uid, required this.name});

  final String uid;
  final String name;

  factory StoreEventSummary.fromJson(Map<String, dynamic> json) {
    return StoreEventSummary(
      uid: (json["uid"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() => {"uid": uid, "name": name};
}

/// Payload from `GET /api/stores/{event|merch}`.
class StoreInfoModel {
  const StoreInfoModel({
    required this.type,
    required this.name,
    required this.isOpen,
    required this.cartCount,
    required this.currency,
    this.closedMessage,
    this.event,
  });

  /// `event` or `merch`.
  final String type;
  final String name;
  final bool isOpen;
  final String? closedMessage;
  final StoreEventSummary? event;
  final int cartCount;
  final StoreCurrency currency;

  factory StoreInfoModel.fromJson(Map<String, dynamic> json) {
    final eventRaw = json["event"];
    StoreEventSummary? event;
    if (eventRaw is Map) {
      event = StoreEventSummary.fromJson(Map<String, dynamic>.from(eventRaw));
    }
    final currencyRaw = json["currency"];
    final currency = currencyRaw is Map
        ? StoreCurrency.fromJson(Map<String, dynamic>.from(currencyRaw))
        : const StoreCurrency(code: "NGN", symbol: "₦");

    return StoreInfoModel(
      type: (json["type"] ?? "").toString(),
      name: (json["name"] ?? "Store").toString(),
      isOpen: json["is_open"] == true,
      closedMessage: json["closed_message"]?.toString(),
      event: event,
      cartCount: (json["cart_count"] as num?)?.toInt() ?? 0,
      currency: currency,
    );
  }

  Map<String, dynamic> toJson() => {
    "type": type,
    "name": name,
    "is_open": isOpen,
    "closed_message": closedMessage,
    "event": event?.toJson(),
    "cart_count": cartCount,
    "currency": currency.toJson(),
  };
}
