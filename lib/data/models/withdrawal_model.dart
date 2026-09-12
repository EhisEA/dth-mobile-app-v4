class WithdrawalBankSummary {
  const WithdrawalBankSummary({
    required this.name,
    required this.accountNumber,
    required this.accountName,
  });

  final String name;
  final String accountNumber;
  final String accountName;

  factory WithdrawalBankSummary.fromJson(Map<String, dynamic> json) {
    return WithdrawalBankSummary(
      name: json["name"]?.toString() ?? "",
      accountNumber: json["account_number"]?.toString() ?? "",
      accountName: json["account_name"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "account_number": accountNumber,
    "account_name": accountName,
  };
}

class Withdrawal {
  const Withdrawal({
    required this.uid,
    required this.amount,
    required this.amountValue,
    required this.fee,
    required this.currency,
    required this.status,
    this.netAmount,
    this.bank,
    this.createdAt,
  });

  final String uid;
  final String amount;
  final int amountValue;
  final num fee;
  final String? netAmount;
  final String currency;
  final String status;
  final WithdrawalBankSummary? bank;
  final String? createdAt;

  bool get isPending {
    final s = status.trim().toLowerCase();
    return s == "pending" || s == "processing" || s == "submitted";
  }

  bool get isSuccessful {
    final s = status.trim().toLowerCase();
    return s == "success" ||
        s == "successful" ||
        s == "completed" ||
        s == "paid";
  }

  String get currencySymbol {
    final code = currency.trim().toUpperCase();
    if (code == "NGN" || code.isEmpty) return "₦";
    if (code == "USD") return "\$";
    return code;
  }

  /// Display amount as API sent it, with currency symbol.
  String get formattedAmountLabel => "$currencySymbol$amount";

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    final bankRaw = json["bank"];
    final bank = bankRaw is Map
        ? WithdrawalBankSummary.fromJson(Map<String, dynamic>.from(bankRaw))
        : null;

    final amountValueRaw = json["amount_value"];
    final amountValue = amountValueRaw is int
        ? amountValueRaw
        : amountValueRaw is num
        ? amountValueRaw.toInt()
        : int.tryParse(amountValueRaw?.toString() ?? "") ?? 0;

    final feeRaw = json["fee"];
    final fee = feeRaw is num
        ? feeRaw
        : num.tryParse(feeRaw?.toString() ?? "") ?? 0;

    return Withdrawal(
      uid: json["uid"]?.toString() ?? "",
      amount: json["amount"]?.toString() ?? amountValue.toString(),
      amountValue: amountValue,
      fee: fee,
      netAmount: json["net_amount"]?.toString(),
      currency: json["currency"]?.toString() ?? "NGN",
      status: json["status"]?.toString() ?? "",
      bank: bank,
      createdAt: json["created_at"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "amount": amount,
    "amount_value": amountValue,
    "fee": fee,
    "net_amount": netAmount,
    "currency": currency,
    "status": status,
    if (bank != null) "bank": bank!.toJson(),
    if (createdAt != null) "created_at": createdAt,
  };
}
