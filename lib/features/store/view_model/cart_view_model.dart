import "package:dth_v4/data/models/store/store.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class CartViewModel extends ChangeNotifier {
  final List<CartLine> _lines = [];
  bool _promoApplied = false;
  StoreShippingAddress? _shippingAddress;

  List<CartLine> get lines => List.unmodifiable(_lines);

  bool get promoApplied => _promoApplied;

  StoreShippingAddress? get shippingAddress => _shippingAddress;

  int get totalItemCount =>
      _lines.fold<int>(0, (sum, line) => sum + line.quantity);

  List<CartLine> linesFor(StoreKind kind) =>
      _lines.where((l) => l.product.kind == kind).toList(growable: false);

  List<CartLine> selectedLinesFor(StoreKind kind) =>
      linesFor(kind).where((l) => l.selected).toList(growable: false);

  bool hasSelected(StoreKind kind) => selectedLinesFor(kind).isNotEmpty;

  int selectedSubtotal(StoreKind kind) =>
      selectedLinesFor(kind).fold<int>(0, (sum, line) => sum + line.lineTotal);

  bool selectedHasOutOfStock(StoreKind kind) => selectedLinesFor(
    kind,
  ).any((l) => l.product.outOfStock || l.product.soldOut);

  int get deliveryFee => 15720;
  int get serviceFee => 1050;
  int get tax => 350;

  int checkoutTotal(StoreKind kind) {
    var total = selectedSubtotal(kind) + deliveryFee + serviceFee + tax;
    if (_promoApplied) {
      total = (total * 0.9).round();
    }
    return total;
  }

  void addToCart({
    required StoreProduct product,
    required int quantity,
    String? selectedSize,
    String? selectedColor,
    String? variantUid,
  }) {
    if (quantity <= 0 || product.soldOut) return;
    final keySize = selectedSize?.trim();
    final keyColor = selectedColor?.trim();
    final keyVariant = variantUid?.trim();

    final index = _lines.indexWhere((l) {
      if (keyVariant != null &&
          keyVariant.isNotEmpty &&
          l.variantUid != null &&
          l.variantUid!.isNotEmpty) {
        return l.variantUid == keyVariant;
      }
      return l.product.id == product.id &&
          (l.selectedSize?.trim() ?? "") == (keySize ?? "") &&
          (l.selectedColor?.trim() ?? "") == (keyColor ?? "");
    });

    if (index >= 0) {
      final existing = _lines[index];
      _lines[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
        selected: true,
        product: product,
        variantUid: keyVariant ?? existing.variantUid,
      );
    } else {
      _lines.add(
        CartLine(
          product: product,
          quantity: quantity,
          selected: true,
          selectedSize: keySize,
          selectedColor: keyColor,
          variantUid: keyVariant,
        ),
      );
    }
    notifyListeners();
  }

  void toggleSelected(String lineKey) {
    final index = _lines.indexWhere((l) => l.lineKey == lineKey);
    if (index < 0) return;
    final line = _lines[index];
    _lines[index] = line.copyWith(selected: !line.selected);
    notifyListeners();
  }

  void increment(String lineKey) {
    final index = _lines.indexWhere((l) => l.lineKey == lineKey);
    if (index < 0) return;
    final line = _lines[index];
    _lines[index] = line.copyWith(quantity: line.quantity + 1);
    notifyListeners();
  }

  void decrementOrRequestRemove(String lineKey) {
    final index = _lines.indexWhere((l) => l.lineKey == lineKey);
    if (index < 0) return;
    final line = _lines[index];
    if (line.quantity <= 1) return;
    _lines[index] = line.copyWith(quantity: line.quantity - 1);
    notifyListeners();
  }

  void removeLine(String lineKey) {
    _lines.removeWhere((l) => l.lineKey == lineKey);
    notifyListeners();
  }

  void setPromoApplied(bool value) {
    if (_promoApplied == value) return;
    _promoApplied = value;
    notifyListeners();
  }

  void setShippingAddress(StoreShippingAddress? address) {
    _shippingAddress = address;
    notifyListeners();
  }

  void clearSelected(StoreKind kind) {
    _lines.removeWhere((l) => l.product.kind == kind && l.selected);
    notifyListeners();
  }
}

final cartViewModelProvider = ChangeNotifierProvider<CartViewModel>((ref) {
  return CartViewModel();
});
