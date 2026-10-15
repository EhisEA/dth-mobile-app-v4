import "package:dth_v4/data/models/store/store_cart_model.dart";
import "package:dth_v4/data/models/store/store_product_dto.dart";
import "package:flutter/foundation.dart";

enum StoreCheckoutSummaryType { charge, discount, unknown }

@immutable
class StoreCheckoutSummaryLine {
  const StoreCheckoutSummaryLine({
    required this.label,
    required this.value,
    this.key,
    this.type = StoreCheckoutSummaryType.unknown,
  });

  final String? key;
  final String label;
  final String value;
  final StoreCheckoutSummaryType type;

  bool get isDiscount => type == StoreCheckoutSummaryType.discount;

  factory StoreCheckoutSummaryLine.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json["type"] ?? "").toString().trim().toLowerCase();
    return StoreCheckoutSummaryLine(
      key: _nullableString(json["key"]),
      label: (json["label"] ?? "").toString(),
      value: (json["value"] ?? "").toString(),
      type: switch (typeRaw) {
        "charge" => StoreCheckoutSummaryType.charge,
        "discount" => StoreCheckoutSummaryType.discount,
        _ => StoreCheckoutSummaryType.unknown,
      },
    );
  }
}

@immutable
class StoreCheckoutTotal {
  const StoreCheckoutTotal({required this.label, required this.value});

  final String label;
  final String value;

  factory StoreCheckoutTotal.fromJson(Map<String, dynamic> json) {
    return StoreCheckoutTotal(
      label: (json["label"] ?? "Total").toString(),
      value: (json["value"] ?? "").toString(),
    );
  }
}

@immutable
class StoreCheckoutPromo {
  const StoreCheckoutPromo({
    required this.code,
    required this.applied,
    this.message,
  });

  final String code;
  final bool applied;
  final String? message;

  factory StoreCheckoutPromo.fromJson(Map<String, dynamic> json) {
    return StoreCheckoutPromo(
      code: (json["code"] ?? "").toString(),
      applied: json["applied"] == true,
      message: _nullableString(json["message"]),
    );
  }
}

@immutable
class StoreCheckoutAddressCountry {
  const StoreCheckoutAddressCountry({
    required this.isoCode,
    required this.name,
  });

  final String isoCode;
  final String name;

  factory StoreCheckoutAddressCountry.fromJson(Map<String, dynamic> json) {
    return StoreCheckoutAddressCountry(
      isoCode: (json["iso_code"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
    );
  }
}

@immutable
class StoreCheckoutAddress {
  const StoreCheckoutAddress({
    required this.uid,
    required this.buildingNumber,
    required this.street,
    required this.country,
    required this.state,
    required this.city,
    required this.phone,
    required this.isDefault,
    required this.formatted,
    this.postalCode,
  });

  final String uid;
  final String buildingNumber;
  final String street;
  final StoreCheckoutAddressCountry country;
  final String state;
  final String city;
  final String? postalCode;
  final String phone;
  final bool isDefault;
  final String formatted;

  String get primaryLine {
    final building = buildingNumber.trim();
    final streetName = street.trim();
    if (building.isEmpty) return streetName;
    return "No. $building, $streetName";
  }

  String get secondaryLine {
    final code = country.isoCode.trim().isNotEmpty
        ? country.isoCode.trim().toUpperCase()
        : country.name;
    return "$state, $code $phone";
  }

  StoreShippingAddress toShippingAddress() {
    return StoreShippingAddress(
      uid: uid,
      buildingNo: buildingNumber,
      streetName: street,
      country: country.name.isNotEmpty ? country.name : country.isoCode,
      state: state,
      city: city,
      postalCode: postalCode ?? "",
      phoneNumber: phone,
    );
  }

  factory StoreCheckoutAddress.fromJson(Map<String, dynamic> json) {
    final countryRaw = json["country"];
    return StoreCheckoutAddress(
      uid: (json["uid"] ?? "").toString(),
      buildingNumber: (json["building_number"] ?? "").toString(),
      street: (json["street"] ?? "").toString(),
      country: countryRaw is Map
          ? StoreCheckoutAddressCountry.fromJson(
              Map<String, dynamic>.from(countryRaw),
            )
          : const StoreCheckoutAddressCountry(isoCode: "", name: ""),
      state: (json["state"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      postalCode: _nullableString(json["postal_code"]),
      phone: (json["phone"] ?? "").toString(),
      isDefault: json["is_default"] == true,
      formatted: (json["formatted"] ?? "").toString(),
    );
  }
}

/// Payload from `POST /api/stores/{store}/checkout/quote`.
@immutable
class StoreCheckoutQuote {
  const StoreCheckoutQuote({
    required this.currency,
    required this.summary,
    required this.total,
    required this.items,
    required this.requiresAddress,
    required this.canCheckout,
    this.promo,
    this.address,
  });

  final StoreCurrencyDto currency;
  final List<StoreCheckoutSummaryLine> summary;
  final StoreCheckoutTotal total;
  final List<StoreCartItem> items;
  final StoreCheckoutPromo? promo;
  final StoreCheckoutAddress? address;
  final bool requiresAddress;
  final bool canCheckout;

  String get currencySymbol =>
      currency.symbol.isNotEmpty ? currency.symbol : "₦";

  bool get hasItemProblems =>
      items.any((i) => i.problem != null && i.problem!.trim().isNotEmpty);

  factory StoreCheckoutQuote.fromJson(Map<String, dynamic> json) {
    final currencyRaw = json["currency"];
    final summaryRaw = json["summary"];
    final totalRaw = json["total"];
    final itemsRaw = json["items"];
    final promoRaw = json["promo"];
    final addressRaw = json["address"];

    return StoreCheckoutQuote(
      currency: currencyRaw is Map
          ? StoreCurrencyDto.fromJson(Map<String, dynamic>.from(currencyRaw))
          : const StoreCurrencyDto(code: "", symbol: ""),
      summary: summaryRaw is List
          ? summaryRaw
                .whereType<Map>()
                .map(
                  (e) => StoreCheckoutSummaryLine.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
      total: totalRaw is Map
          ? StoreCheckoutTotal.fromJson(Map<String, dynamic>.from(totalRaw))
          : const StoreCheckoutTotal(label: "Total", value: "0"),
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map(
                  (e) => StoreCartItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
      promo: promoRaw is Map
          ? StoreCheckoutPromo.fromJson(Map<String, dynamic>.from(promoRaw))
          : null,
      address: addressRaw is Map
          ? StoreCheckoutAddress.fromJson(Map<String, dynamic>.from(addressRaw))
          : null,
      requiresAddress: json["requires_address"] == true,
      canCheckout: json["can_checkout"] == true,
    );
  }
}

/// Order summary from `POST /api/stores/{store}/checkout`.
@immutable
class StoreCheckoutOrder {
  const StoreCheckoutOrder({
    required this.uid,
    required this.number,
    required this.status,
    this.reservedUntil,
  });

  final String uid;
  final String number;
  final String status;
  final String? reservedUntil;

  factory StoreCheckoutOrder.fromJson(Map<String, dynamic> json) {
    return StoreCheckoutOrder(
      uid: (json["uid"] ?? "").toString(),
      number: (json["number"] ?? "").toString(),
      status: (json["status"] ?? "").toString(),
      reservedUntil: _nullableString(json["reserved_until"]),
    );
  }
}

/// Payload from `POST /api/stores/{store}/checkout`.
@immutable
class StoreCheckoutResult {
  const StoreCheckoutResult({
    required this.order,
    required this.currency,
    required this.summary,
    required this.total,
    required this.requiresPayment,
    this.authorizationUrl,
    this.reference,
    this.callbackUrl,
  });

  final StoreCheckoutOrder order;
  final StoreCurrencyDto currency;
  final List<StoreCheckoutSummaryLine> summary;
  final StoreCheckoutTotal total;
  final bool requiresPayment;
  final String? authorizationUrl;
  final String? reference;
  final String? callbackUrl;

  factory StoreCheckoutResult.fromJson(Map<String, dynamic> json) {
    final orderRaw = json["order"];
    final currencyRaw = json["currency"];
    final summaryRaw = json["summary"];
    final totalRaw = json["total"];

    return StoreCheckoutResult(
      order: orderRaw is Map
          ? StoreCheckoutOrder.fromJson(Map<String, dynamic>.from(orderRaw))
          : const StoreCheckoutOrder(uid: "", number: "", status: ""),
      currency: currencyRaw is Map
          ? StoreCurrencyDto.fromJson(Map<String, dynamic>.from(currencyRaw))
          : const StoreCurrencyDto(code: "", symbol: ""),
      summary: summaryRaw is List
          ? summaryRaw
                .whereType<Map>()
                .map(
                  (e) => StoreCheckoutSummaryLine.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
      total: totalRaw is Map
          ? StoreCheckoutTotal.fromJson(Map<String, dynamic>.from(totalRaw))
          : const StoreCheckoutTotal(label: "Total", value: "0"),
      requiresPayment: json["requires_payment"] == true,
      authorizationUrl: _nullableString(json["authorization_url"]),
      reference: _nullableString(json["reference"]),
      callbackUrl: _nullableString(json["callback_url"]),
    );
  }
}

/// Item that could not be restored to the cart after abandoning payment.
@immutable
class StoreAbandonSkippedItem {
  const StoreAbandonSkippedItem({required this.name, required this.reason});

  final String name;
  final String reason;

  factory StoreAbandonSkippedItem.fromJson(Map<String, dynamic> json) {
    return StoreAbandonSkippedItem(
      name: (json["name"] ?? "").toString(),
      reason: (json["reason"] ?? "").toString(),
    );
  }
}

/// `event` values from `POST /api/store/orders/{order}/abandon` failures.
abstract final class StoreAbandonEvents {
  static const orderNotFound = "order_not_found";
  static const orderAlreadyPaid = "order_already_paid";
  static const orderNotAwaitingPayment = "order_not_awaiting_payment";
  static const paymentCheckFailed = "payment_check_failed";
}

/// Payload from `POST /api/store/orders/{order}/abandon`.
@immutable
class StoreAbandonOrderResult {
  const StoreAbandonOrderResult({
    required this.isPaid,
    required this.added,
    required this.skipped,
    required this.storeType,
    required this.count,
    this.message = "",
  });

  final bool isPaid;
  final int added;
  final List<StoreAbandonSkippedItem> skipped;
  final String storeType;
  final int count;
  final String message;

  factory StoreAbandonOrderResult.fromJson(
    Map<String, dynamic> json, {
    String message = "",
  }) {
    final skippedRaw = json["skipped"];
    return StoreAbandonOrderResult(
      isPaid: json["is_paid"] == true,
      added: (json["added"] as num?)?.toInt() ?? 0,
      skipped: skippedRaw is List
          ? skippedRaw
                .whereType<Map>()
                .map(
                  (e) => StoreAbandonSkippedItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
      storeType: (json["store_type"] ?? "").toString(),
      count: (json["count"] as num?)?.toInt() ?? 0,
      message: message,
    );
  }
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
