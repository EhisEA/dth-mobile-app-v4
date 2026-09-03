class VoteCreditQuote {
  const VoteCreditQuote({
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.currency,
  });

  final int quantity;
  final int unitPrice;
  final int amount;
  final String currency;

  String get currencySymbol {
    final code = currency.trim().toUpperCase();
    if (code == "NGN" || code.isEmpty) return "₦";
    if (code == "USD") return "\$";
    return code;
  }

  factory VoteCreditQuote.fromJson(Map<String, dynamic> json) {
    return VoteCreditQuote(
      quantity: _asInt(json["quantity"]),
      unitPrice: _asInt(json["unit_price"]),
      amount: _asInt(json["amount"]),
      currency: json["currency"]?.toString() ?? "NGN",
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }
}
