import "package:dth_v4/data/models/available_ticket_model.dart";
import "package:dth_v4/data/models/subscription_purchase_init.dart";
import "package:dth_v4/data/models/ticket_purchase_line_model.dart";
import "package:flutter_utils/flutter_utils.dart";

abstract class TicketsRepo {
  Future<List<AvailableTicket>> fetchAvailableTickets(String eventUid);

  /// Initializes Paystack checkout (same payload shape as subscription purchase).
  Future<ApiResponse<SubscriptionPurchaseInit>> purchaseTickets({
    required String eventUid,
    required List<TicketPurchaseLine> lines,
  });

  Future<ApiResponse<void>> verifyPayment({required String reference});
}
