class AvailableTicket {
  const AvailableTicket({
    required this.uid,
    required this.type,
    required this.label,
    required this.description,
    required this.amount,
    required this.iconUrl,
    required this.availableTickets,
  });

  final String uid;
  final String type;
  final String label;
  final String description;
  final String amount;
  final String iconUrl;
  final int availableTickets;

  double get amountValue => double.tryParse(amount.replaceAll(",", "")) ?? 0;

  factory AvailableTicket.fromJson(Map<String, dynamic> json) {
    final stockRaw = json["available_tickets"];
    final stock = stockRaw is int
        ? stockRaw
        : stockRaw is num
        ? stockRaw.toInt()
        : 0;

    return AvailableTicket(
      uid: json["uid"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      amount: json["amount"]?.toString() ?? "0",
      iconUrl: json["icon_url"]?.toString() ?? "",
      availableTickets: stock,
    );
  }
}
