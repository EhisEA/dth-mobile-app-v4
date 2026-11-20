import "package:dth_v4/features/voting/models/voting_running_low_prompt.dart";

class VotingCreditInfo {
  const VotingCreditInfo({
    required this.minAmount,
    required this.maxAmount,
    required this.minCredit,
    required this.maxCredit,
    this.runningLow,
  });

  /// Minimum NGN amount for a top-up (`min_amount`).
  final int minAmount;

  /// Maximum NGN amount for a top-up (`max_amount`).
  final int maxAmount;

  /// Minimum credits a purchase can grant (`min_credit`).
  final int minCredit;

  /// Maximum credits a purchase can grant (`max_credit`).
  final int maxCredit;

  /// Popup copy when the user's credits are low (`running_low`); null when the
  /// backend sends `false` or omits it.
  final VotingRunningLowPrompt? runningLow;

  bool get isRunningLow => runningLow != null;

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
      runningLow: VotingRunningLowPrompt.tryParse(json["running_low"]),
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
