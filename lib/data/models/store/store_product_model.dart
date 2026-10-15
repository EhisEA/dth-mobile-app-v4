import "package:dth_v4/data/models/store/store_kind.dart";
import "package:dth_v4/data/models/store/store_product_dto.dart";
import "package:flutter/foundation.dart";

@immutable
class StoreProductColor {
  const StoreProductColor({required this.name, required this.hex});

  final String name;
  final String hex;

  factory StoreProductColor.fromDto(StoreProductColorDto dto) {
    return StoreProductColor(name: dto.name, hex: dto.hex);
  }
}

@immutable
class StoreProductVariant {
  const StoreProductVariant({
    required this.uid,
    required this.size,
    required this.available,
    this.color,
    this.soldOut = false,
  });

  final String uid;
  final String size;
  final StoreProductColor? color;
  final int available;
  final bool soldOut;

  bool get isAvailable => !soldOut && available > 0;

  factory StoreProductVariant.fromDto(StoreProductVariantDto dto) {
    return StoreProductVariant(
      uid: dto.uid,
      size: dto.size,
      available: dto.available,
      soldOut: dto.isSoldOut,
      color: dto.color == null ? null : StoreProductColor.fromDto(dto.color!),
    );
  }
}

@immutable
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.kind,
    required this.title,
    required this.storeName,
    required this.imageUrl,
    required this.price,
    required this.currencySymbol,
    this.currencyCode = "",
    this.description = "",
    this.originalPrice,
    this.apiDiscountPercent,
    this.sizes = const [],
    this.soldOut = false,
    this.outOfStock = false,
    this.isFree = false,
    this.sponsorshipTerms,
    this.category,
    this.terms,
    this.images = const [],
    this.maxPerOrder,
    this.colors = const [],
    this.variants = const [],
  });

  final String id;
  final StoreKind kind;
  final String title;
  final String storeName;
  final String description;
  final String imageUrl;
  final int price;
  final int? originalPrice;
  final int? apiDiscountPercent;
  final List<String> sizes;
  final bool soldOut;
  final bool outOfStock;
  final bool isFree;
  final String? sponsorshipTerms;
  final String currencyCode;
  final String currencySymbol;
  final String? category;
  final String? terms;
  final List<String> images;
  final int? maxPerOrder;
  final List<StoreProductColor> colors;
  final List<StoreProductVariant> variants;

  /// Prefer gallery images; fall back to the list thumbnail.
  List<String> get galleryImages {
    if (images.isNotEmpty) return images;
    if (imageUrl.trim().isEmpty) return const [];
    return [imageUrl];
  }

  factory StoreProduct.fromDto(
    StoreProductDto dto, {
    required StoreKind kind,
    required String currencyCode,
    required String currencySymbol,
  }) {
    return StoreProduct(
      id: dto.uid,
      kind: kind,
      title: dto.name,
      storeName: dto.vendor,
      description: dto.description,
      imageUrl: dto.imageUrl,
      price: dto.price,
      originalPrice: dto.compareAtPrice,
      apiDiscountPercent: dto.discountPercent,
      sizes: dto.sizes,
      soldOut: dto.isSoldOut,
      isFree: dto.isFree,
      sponsorshipTerms: dto.sponsorLabel,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol.isNotEmpty ? currencySymbol : "₦",
    );
  }

  factory StoreProduct.fromDetail(
    StoreProductDetailDto dto, {
    required StoreKind kind,
    required String currencyCode,
    required String currencySymbol,
  }) {
    final symbol = currencySymbol.isNotEmpty ? currencySymbol : "₦";
    return StoreProduct(
      id: dto.uid,
      kind: kind,
      title: dto.name,
      storeName: dto.vendor,
      imageUrl: dto.imageUrl,
      price: dto.price,
      originalPrice: dto.compareAtPrice,
      apiDiscountPercent: dto.discountPercent,
      sizes: dto.sizes,
      soldOut: dto.isSoldOut,
      isFree: dto.isFree,
      sponsorshipTerms: dto.sponsorLabel,
      currencyCode: currencyCode,
      currencySymbol: symbol,
      category: dto.category,
      description: dto.description,
      terms: dto.terms,
      images: dto.images,
      maxPerOrder: dto.maxPerOrder,
      colors: [for (final c in dto.colors) StoreProductColor.fromDto(c)],
      variants: [for (final v in dto.variants) StoreProductVariant.fromDto(v)],
    );
  }

  int? get discountPercent {
    final api = apiDiscountPercent;
    if (api != null && api > 0) return api;
    final original = originalPrice;
    if (original == null || original <= price || original <= 0) return null;
    return (((original - price) / original) * 100).round();
  }

  StoreProductVariant? variantFor({String? size, String? colorName}) {
    final sizeKey = size?.trim();
    final colorKey = colorName?.trim();
    for (final v in variants) {
      final sizeOk = sizeKey == null || sizeKey.isEmpty || v.size == sizeKey;
      final colorOk =
          colorKey == null ||
          colorKey.isEmpty ||
          (v.color?.name ?? "") == colorKey;
      if (sizeOk && colorOk) return v;
    }
    return null;
  }

  /// Resolves the cart variant for the user's size + colour picks.
  ///
  /// Does **not** invent another colour when the combo is missing — size and
  /// colour stay independent in the UI. Falls back only to a size variant that
  /// has no colour (universal size).
  StoreProductVariant? resolveVariant({String? size, String? colorName}) {
    final exact = variantFor(size: size, colorName: colorName);
    if (exact != null) return exact;

    final sizeKey = size?.trim();
    if (sizeKey == null || sizeKey.isEmpty) return null;

    for (final v in variants) {
      if (v.size == sizeKey && v.color == null) return v;
    }
    return null;
  }

  bool hasAvailableSize(String size) =>
      variants.isEmpty || variants.any((v) => v.size == size && v.isAvailable);

  bool hasAvailableColor(String colorName) =>
      variants.isEmpty ||
      variants.any((v) => (v.color?.name ?? "") == colorName && v.isAvailable);

  /// Colors that exist on variants for [size]. Empty when that size has no colour.
  List<StoreProductColor> colorsForSize(String? size) {
    if (variants.isEmpty) return colors;
    final sizeKey = size?.trim();
    if (sizeKey == null || sizeKey.isEmpty) return colors;

    final seen = <String>{};
    final result = <StoreProductColor>[];
    for (final v in variants) {
      if (v.size != sizeKey) continue;
      final color = v.color;
      if (color == null) continue;
      if (seen.add(color.name)) result.add(color);
    }
    return result;
  }

  bool hasAvailableColorForSize(String colorName, String? size) {
    if (variants.isEmpty) return true;
    final sizeKey = size?.trim();
    return variants.any((v) {
      final sizeOk =
          sizeKey == null || sizeKey.isEmpty || v.size == sizeKey;
      return sizeOk &&
          (v.color?.name ?? "") == colorName &&
          v.isAvailable;
    });
  }
}
