import "package:dth_v4/data/models/subscription_purchase_init.dart";
import "package:flutter_utils/flutter_utils.dart";

abstract class TicketsRepo {
  /// Initializes Paystack checkout (same payload shape as subscription purchase).
  Future<ApiResponse<SubscriptionPurchaseInit>> purchaseTickets({
    required String eventUid,
    required String seatTypeUid,
    int quantity = 1,
  });

  Future<ApiResponse<void>> verifyPayment({required String reference});
}
