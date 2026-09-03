class VotingCreditInfo {
  const VotingCreditInfo({
    required this.minAmount,
    required this.maxAmount,
    required this.minCredit,
    required this.maxCredit,
  });

  /// Minimum NGN amount for a top-up (`min_amount`).
  final int minAmount;

  /// Maximum NGN amount for a top-up (`max_amount`).
  final int maxAmount;

  /// Minimum credits a purchase can grant (`min_credit`).
  final int minCredit;

  /// Maximum credits a purchase can grant (`max_credit`).
  final int maxCredit;

  bool isAmountInRange(int amount) =>
      amount >= minAmount && amount <= maxAmount;

  bool isCreditInRange(int quantity) =>
      quantity >= minCredit && quantity <= maxCredit;

  factory VotingCreditInfo.fromJson(Map<String, dynamic> json) {
    return VotingCreditInfo(
      minAmount: _asInt(json["min_amount"], fallback.minAmount),
      maxAmount: _asInt(json["max_amount"], fallback.maxAmount),
      minCredit: _asInt(json["min_credit"], fallback.minCredit),
      maxCredit: _asInt(json["max_credit"], fallback.maxCredit),
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? fallback;
  }

  static const fallback = VotingCreditInfo(
    minAmount: 100,
    maxAmount: 1000000,
    minCredit: 10,
    maxCredit: 100000,
  );
}
