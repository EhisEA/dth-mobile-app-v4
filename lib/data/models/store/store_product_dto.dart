import "package:dth_v4/data/models/paginated_result.dart";
import "package:flutter/foundation.dart";

@immutable
class StoreCurrencyDto {
  const StoreCurrencyDto({required this.code, required this.symbol});

  final String code;
  final String symbol;

  factory StoreCurrencyDto.fromJson(Map<String, dynamic> json) {
    return StoreCurrencyDto(
      code: (json["code"] ?? "").toString(),
      symbol: (json["symbol"] ?? "").toString(),
    );
  }
}

@immutable
class StoreProductColorDto {
  const StoreProductColorDto({required this.name, required this.hex});

  final String name;
  final String hex;

  factory StoreProductColorDto.fromJson(Map<String, dynamic> json) {
    return StoreProductColorDto(
      name: (json["name"] ?? "").toString(),
      hex: (json["hex"] ?? "").toString(),
    );
  }
}

@immutable
class StoreProductVariantDto {
  const StoreProductVariantDto({
    required this.uid,
    required this.size,
    required this.available,
    this.color,
    this.isSoldOut = false,
  });

  final String uid;
  final String size;
  final StoreProductColorDto? color;
  final int available;
  final bool isSoldOut;

  factory StoreProductVariantDto.fromJson(Map<String, dynamic> json) {
    final colorRaw = json["color"];
    return StoreProductVariantDto(
      uid: (json["uid"] ?? "").toString(),
      size: (json["size"] ?? "").toString(),
      color: colorRaw is Map
          ? StoreProductColorDto.fromJson(Map<String, dynamic>.from(colorRaw))
          : null,
      available: (json["available"] as num?)?.toInt() ?? 0,
      isSoldOut: json["is_sold_out"] == true,
    );
  }
}

@immutable
class StoreProductDto {
  const StoreProductDto({
    required this.uid,
    required this.name,
    required this.vendor,
    required this.imageUrl,
    required this.price,
    this.compareAtPrice,
    this.discountPercent,
    this.isFree = false,
    this.sponsorLabel,
    this.isSoldOut = false,
    this.sizes = const [],
  });

  final String uid;
  final String name;
  final String vendor;
  final String imageUrl;

  /// Whole currency units (fractional part discarded).
  final int price;
  final int? compareAtPrice;
  final int? discountPercent;
  final bool isFree;
  final String? sponsorLabel;
  final bool isSoldOut;
  final List<String> sizes;

  factory StoreProductDto.fromJson(Map<String, dynamic> json) {
    final sizesRaw = json["sizes"];
    final sizes = sizesRaw is List
        ? sizesRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const <String>[];

    return StoreProductDto(
      uid: (json["uid"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      vendor: (json["vendor"] ?? "").toString(),
      imageUrl: (json["image_url"] ?? "").toString(),
      price: _parseMoney(json["price"]) ?? 0,
      compareAtPrice: _parseMoney(json["compare_at_price"]),
      discountPercent: _parseInt(json["discount_percent"]),
      isFree: json["is_free"] == true,
      sponsorLabel: _nullableString(json["sponsor_label"]),
      isSoldOut: json["is_sold_out"] == true,
      sizes: sizes,
    );
  }
}

@immutable
class StoreProductDetailDto {
  const StoreProductDetailDto({
    required this.uid,
    required this.name,
    required this.vendor,
    required this.imageUrl,
    required this.price,
    this.compareAtPrice,
    this.discountPercent,
    this.isFree = false,
    this.sponsorLabel,
    this.isSoldOut = false,
    this.sizes = const [],
    this.category,
    this.description = "",
    this.terms,
    this.images = const [],
    this.maxPerOrder,
    this.colors = const [],
    this.variants = const [],
  });

  final String uid;
  final String name;
  final String vendor;
  final String imageUrl;
  final int price;
  final int? compareAtPrice;
  final int? discountPercent;
  final bool isFree;
  final String? sponsorLabel;
  final bool isSoldOut;
  final List<String> sizes;
  final String? category;
  final String description;
  final String? terms;
  final List<String> images;
  final int? maxPerOrder;
  final List<StoreProductColorDto> colors;
  final List<StoreProductVariantDto> variants;

  factory StoreProductDetailDto.fromJson(Map<String, dynamic> json) {
    final sizesRaw = json["sizes"];
    final sizes = sizesRaw is List
        ? sizesRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const <String>[];

    final imagesRaw = json["images"];
    final images = imagesRaw is List
        ? imagesRaw
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList()
        : const <String>[];

    final colorsRaw = json["colors"];
    final colors = colorsRaw is List
        ? colorsRaw
              .whereType<Map>()
              .map(
                (e) =>
                    StoreProductColorDto.fromJson(Map<String, dynamic>.from(e)),
              )
              .where((c) => c.name.isNotEmpty)
              .toList(growable: false)
        : const <StoreProductColorDto>[];

    final variantsRaw = json["variants"];
    final variants = variantsRaw is List
        ? variantsRaw
              .whereType<Map>()
              .map(
                (e) => StoreProductVariantDto.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .where((v) => v.uid.isNotEmpty)
              .toList(growable: false)
        : const <StoreProductVariantDto>[];

    return StoreProductDetailDto(
      uid: (json["uid"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      vendor: (json["vendor"] ?? "").toString(),
      imageUrl: (json["image_url"] ?? "").toString(),
      price: _parseMoney(json["price"]) ?? 0,
      compareAtPrice: _parseMoney(json["compare_at_price"]),
      discountPercent: _parseInt(json["discount_percent"]),
      isFree: json["is_free"] == true,
      sponsorLabel: _nullableString(json["sponsor_label"]),
      isSoldOut: json["is_sold_out"] == true,
      sizes: sizes,
      category: _nullableString(json["category"]),
      description: (json["description"] ?? "").toString(),
      terms: _nullableString(json["terms"]),
      images: images,
      maxPerOrder: _parseInt(json["max_per_order"]),
      colors: colors,
      variants: variants,
    );
  }
}

@immutable
class StoreProductsPage {
  const StoreProductsPage({required this.currency, required this.products});

  final StoreCurrencyDto currency;
  final PaginatedResult<StoreProductDto> products;
}

@immutable
class StoreProductDetailResult {
  const StoreProductDetailResult({
    required this.currency,
    required this.product,
  });

  final StoreCurrencyDto currency;
  final StoreProductDetailDto product;
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
