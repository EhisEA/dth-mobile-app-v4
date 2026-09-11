class BankAccount {
  const BankAccount({
    required this.url,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  final String url;
  final String bankName;
  final String accountNumber;
  final String accountName;

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      url: json["url"]?.toString() ?? "",
      bankName: json["bank_name"]?.toString() ?? "",
      accountNumber: json["account_number"]?.toString() ?? "",
      accountName: json["account_name"]?.toString() ?? "",
    );
  }
}
