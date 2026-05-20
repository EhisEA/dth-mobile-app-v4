class TicketPurchaseLine {
  const TicketPurchaseLine({
    required this.seatTypeUid,
    required this.quantity,
    required this.amount,
  });

  final String seatTypeUid;
  final int quantity;

  /// Line total for this seat type (unit price × quantity).
  final double amount;

  Map<String, dynamic> toJson() => {
    "seat_type_uid": seatTypeUid,
    "quantity": quantity,
    "amount": amount,
  };
}
