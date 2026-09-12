class BankInstitution {
  const BankInstitution({required this.uid, required this.name, this.imageUrl});

  final String uid;
  final String name;
  final String? imageUrl;

  factory BankInstitution.fromJson(Map<String, dynamic> json) {
    return BankInstitution(
      uid: json["uid"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      imageUrl: _nullableUrl(json["image_url"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "name": name,
    if (imageUrl != null) "image_url": imageUrl,
  };
}

class BankAccountDeleteOtpSession {
  const BankAccountDeleteOtpSession({
    required this.signature,
    required this.expiresIn,
  });

  final String signature;
  final int expiresIn;

  factory BankAccountDeleteOtpSession.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json["expires_in"];
    final expiresIn = expiresRaw is int
        ? expiresRaw
        : int.tryParse(expiresRaw?.toString() ?? "") ?? 600;
    return BankAccountDeleteOtpSession(
      signature: json["signature"]?.toString() ?? "",
      expiresIn: expiresIn > 0 ? expiresIn : 600,
    );
  }
}

class BankAccount {
  const BankAccount({
    required this.uid,
    required this.bankUid,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.isDefault = false,
    this.imageUrl,
  });

  final String uid;
  final String bankUid;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool isDefault;

  /// Optional bank logo from nested `bank.image_url` (may be null).
  final String? imageUrl;

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    final bankRaw = json["bank"];
    final bank = bankRaw is Map<String, dynamic>
        ? bankRaw
        : bankRaw is Map
        ? Map<String, dynamic>.from(bankRaw)
        : const <String, dynamic>{};

    return BankAccount(
      uid: json["uid"]?.toString() ?? "",
      bankUid: bank["uid"]?.toString() ?? "",
      bankName: bank["name"]?.toString() ?? json["bank_name"]?.toString() ?? "",
      accountNumber: json["account_number"]?.toString() ?? "",
      accountName: json["account_name"]?.toString() ?? "",
      isDefault: json["is_default"] == true,
      imageUrl: _nullableUrl(bank["image_url"] ?? json["image_url"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "bank": {
      "uid": bankUid,
      "name": bankName,
      if (imageUrl != null) "image_url": imageUrl,
    },
    "account_number": accountNumber,
    "account_name": accountName,
    "is_default": isDefault,
  };
}

String? _nullableUrl(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
