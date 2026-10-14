import "package:dth_v4/data/models/store/store_kind.dart";
import "package:dth_v4/data/models/store/store_product_dto.dart";
import "package:dth_v4/data/models/store/store_product_model.dart";
import "package:flutter/foundation.dart";

/// Payload from `POST /api/store/cart/items`.
@immutable
class StoreCartAddResult {
  const StoreCartAddResult({
    required this.itemUid,
    required this.quantity,
    required this.count,
  });

  final String itemUid;

  /// Quantity of this line after the add (server may have merged).
  final int quantity;

  /// Total items in the cart (badge count).
  final int count;

  factory StoreCartAddResult.fromJson(Map<String, dynamic> json) {
    return StoreCartAddResult(
      itemUid: (json["item_uid"] ?? "").toString(),
      quantity: (json["quantity"] as num?)?.toInt() ?? 0,
      count: (json["count"] as num?)?.toInt() ?? 0,
    );
  }
}

/// Payload from `PATCH /api/store/cart/items/{id}`.
@immutable
class StoreCartUpdateResult {
  const StoreCartUpdateResult({
    required this.itemUid,
    required this.quantity,
    required this.isSelected,
  });

  final String itemUid;
  final int quantity;
  final bool isSelected;

  factory StoreCartUpdateResult.fromJson(Map<String, dynamic> json) {
    return StoreCartUpdateResult(
      itemUid: (json["item_uid"] ?? "").toString(),
      quantity: (json["quantity"] as num?)?.toInt() ?? 0,
      isSelected: json["is_selected"] == true,
    );
  }
}

@immutable
class StoreCartProductSummary {
  const StoreCartProductSummary({
    required this.uid,
    required this.name,
    required this.vendor,
    required this.imageUrl,
  });

  final String uid;
  final String name;
  final String vendor;
  final String imageUrl;

  factory StoreCartProductSummary.fromJson(Map<String, dynamic> json) {
    return StoreCartProductSummary(
      uid: (json["uid"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      vendor: (json["vendor"] ?? "").toString(),
      imageUrl: (json["image_url"] ?? "").toString(),
    );
  }
}

@immutable
class StoreCartVariantSummary {
  const StoreCartVariantSummary({
    required this.uid,
    required this.size,
    this.color,
  });

  final String uid;
  final String size;
  final StoreProductColorDto? color;

  factory StoreCartVariantSummary.fromJson(Map<String, dynamic> json) {
    final colorRaw = json["color"];
    return StoreCartVariantSummary(
      uid: (json["uid"] ?? "").toString(),
      size: (json["size"] ?? "").toString(),
      color: colorRaw is Map
          ? StoreProductColorDto.fromJson(Map<String, dynamic>.from(colorRaw))
          : null,
    );
  }
}

@immutable
class StoreCartItem {
  const StoreCartItem({
    required this.uid,
    required this.quantity,
    required this.isSelected,
    required this.product,
    required this.variant,
    required this.unitPrice,
    required this.lineTotal,
    required this.available,
    this.maxPerOrder,
    this.problem,
  });

  final String uid;
  final int quantity;
  final bool isSelected;
  final StoreCartProductSummary product;
  final StoreCartVariantSummary variant;
  final int unitPrice;
  final int lineTotal;
  final int available;
  final int? maxPerOrder;
  final String? problem;

  bool get hasProblem => problem != null && problem!.trim().isNotEmpty;

  bool get canCheckout => isSelected && !hasProblem;

  factory StoreCartItem.fromJson(Map<String, dynamic> json) {
    final productRaw = json["product"];
    final variantRaw = json["variant"];
    return StoreCartItem(
      uid: (json["uid"] ?? "").toString(),
      quantity: (json["quantity"] as num?)?.toInt() ?? 0,
      isSelected: json["is_selected"] == true,
      product: productRaw is Map
          ? StoreCartProductSummary.fromJson(
              Map<String, dynamic>.from(productRaw),
            )
          : const StoreCartProductSummary(
              uid: "",
              name: "",
              vendor: "",
              imageUrl: "",
            ),
      variant: variantRaw is Map
          ? StoreCartVariantSummary.fromJson(
              Map<String, dynamic>.from(variantRaw),
            )
          : const StoreCartVariantSummary(uid: "", size: ""),
      unitPrice: _parseMoney(json["unit_price"]) ?? 0,
      lineTotal: _parseMoney(json["line_total"]) ?? 0,
      available: (json["available"] as num?)?.toInt() ?? 0,
      maxPerOrder: _parseInt(json["max_per_order"]),
      problem: _nullableString(json["problem"]),
    );
  }

  StoreCartItem copyWith({
    String? uid,
    int? quantity,
    bool? isSelected,
    StoreCartProductSummary? product,
    StoreCartVariantSummary? variant,
    int? unitPrice,
    int? lineTotal,
    int? available,
    int? maxPerOrder,
    String? problem,
    bool clearProblem = false,
  }) {
    return StoreCartItem(
      uid: uid ?? this.uid,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
      product: product ?? this.product,
      variant: variant ?? this.variant,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      available: available ?? this.available,
      maxPerOrder: maxPerOrder ?? this.maxPerOrder,
      problem: clearProblem ? null : (problem ?? this.problem),
    );
  }
}

@immutable
class StoreCartStoreBlock {
  const StoreCartStoreBlock({
    required this.type,
    required this.name,
    required this.isOpen,
    required this.count,
    required this.selectedSubtotal,
    required this.items,
  });

  /// `event` or `merch`.
  final String type;
  final String name;
  final bool isOpen;
  final int count;
  final int selectedSubtotal;
  final List<StoreCartItem> items;

  StoreKind get kind => type == "event" ? StoreKind.liveEvent : StoreKind.merch;

  bool get hasSelectedCheckoutable => items.any((i) => i.canCheckout);

  factory StoreCartStoreBlock.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json["items"];
    final items = itemsRaw is List
        ? itemsRaw
              .whereType<Map>()
              .map((e) => StoreCartItem.fromJson(Map<String, dynamic>.from(e)))
              .where((i) => i.uid.isNotEmpty)
              .toList(growable: false)
        : const <StoreCartItem>[];

    return StoreCartStoreBlock(
      type: (json["type"] ?? "").toString(),
      name: (json["name"] ?? "Store").toString(),
      isOpen: json["is_open"] == true,
      count: (json["count"] as num?)?.toInt() ?? 0,
      selectedSubtotal: _parseMoney(json["selected_subtotal"]) ?? 0,
      items: items,
    );
  }

  StoreCartStoreBlock copyWith({List<StoreCartItem>? items, int? count}) {
    return StoreCartStoreBlock(
      type: type,
      name: name,
      isOpen: isOpen,
      count: count ?? this.count,
      selectedSubtotal: selectedSubtotal,
      items: items ?? this.items,
    );
  }
}

@immutable
class StoreCartData {
  const StoreCartData({
    required this.currency,
    required this.count,
    required this.stores,
  });

  final StoreCurrencyDto currency;
  final int count;
  final List<StoreCartStoreBlock> stores;

  List<StoreCartItem> get allItems => [
    for (final store in stores) ...store.items,
  ];

  bool get isEmpty => allItems.isEmpty;

  factory StoreCartData.fromJson(Map<String, dynamic> json) {
    final currencyRaw = json["currency"];
    final storesRaw = json["stores"];
    return StoreCartData(
      currency: currencyRaw is Map
          ? StoreCurrencyDto.fromJson(Map<String, dynamic>.from(currencyRaw))
          : const StoreCurrencyDto(code: "", symbol: "₦"),
      count: (json["count"] as num?)?.toInt() ?? 0,
      stores: storesRaw is List
          ? storesRaw
                .whereType<Map>()
                .map(
                  (e) => StoreCartStoreBlock.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .where((s) => s.items.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}

/// Local checkout / shipping helpers (not from cart GET).
@immutable
class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    required this.selected,
    this.selectedSize,
    this.selectedColor,
    this.variantUid,
    this.cartItemUid,
  });

  final StoreProduct product;
  final int quantity;
  final bool selected;
  final String? selectedSize;
  final String? selectedColor;
  final String? variantUid;
  final String? cartItemUid;

  String get lineKey {
    final item = cartItemUid?.trim();
    if (item != null && item.isNotEmpty) return item;
    final variant = variantUid?.trim();
    if (variant != null && variant.isNotEmpty) return variant;
    final size = selectedSize?.trim().isEmpty ?? true ? "_" : selectedSize;
    final color = selectedColor?.trim().isEmpty ?? true ? "_" : selectedColor;
    return "${product.id}|$size|$color";
  }

  int get lineTotal => product.price * quantity;

  CartLine copyWith({
    StoreProduct? product,
    int? quantity,
    bool? selected,
    String? selectedSize,
    String? selectedColor,
    String? variantUid,
    String? cartItemUid,
  }) {
    return CartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selected: selected ?? this.selected,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      variantUid: variantUid ?? this.variantUid,
      cartItemUid: cartItemUid ?? this.cartItemUid,
    );
  }
}

@immutable
class StoreShippingAddress {
  const StoreShippingAddress({
    required this.buildingNo,
    required this.streetName,
    required this.country,
    required this.state,
    required this.city,
    required this.postalCode,
    required this.phoneNumber,
    this.uid,
  });

  /// Server address uid from checkout quote (when available).
  final String? uid;
  final String buildingNo;
  final String streetName;
  final String country;
  final String state;
  final String city;
  final String postalCode;
  final String phoneNumber;

  String get primaryLine {
    final building = buildingNo.trim();
    final street = streetName.trim();
    if (building.isEmpty) return street;
    return "No. $building, $street";
  }

  String get countryCode {
    switch (country.trim().toLowerCase()) {
      case "nigeria":
        return "NG";
      default:
        final trimmed = country.trim();
        if (trimmed.length >= 2) {
          return trimmed.substring(0, 2).toUpperCase();
        }
        return trimmed.toUpperCase();
    }
  }

  String get formattedPhone {
    final digits = phoneNumber.replaceAll(RegExp(r"\D"), "");
    if (digits.isEmpty) return phoneNumber.trim();
    if (digits.startsWith("234") && digits.length >= 13) {
      final local = digits.substring(3);
      return "+234(0)$local";
    }
    if (digits.startsWith("0") && digits.length >= 11) {
      return "+234(0)${digits.substring(1)}";
    }
    return phoneNumber.trim();
  }

  String get secondaryLine => "$state, $countryCode $formattedPhone";
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
