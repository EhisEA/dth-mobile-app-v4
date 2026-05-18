import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class TicketsRepoImpl implements TicketsRepo {
  TicketsRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<List<AvailableTicket>> fetchAvailableTickets(String eventUid) async {
    final response = await _networkService.get(
      ApiRoute.eventAvailableTickets(eventUid),
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) return const [];
    final data = root["data"];
    if (data is! Map<String, dynamic>) return const [];
    final list = data["available_tickets"];
    if (list is! List<dynamic>) return const [];

    return list
        .map((e) {
          if (e is! Map) return null;
          final ticket = AvailableTicket.fromJson(
            Map<String, dynamic>.from(e),
          );
          return ticket.uid.isNotEmpty ? ticket : null;
        })
        .whereType<AvailableTicket>()
        .toList();
  }

  @override
  Future<ApiResponse<SubscriptionPurchaseInit>> purchaseTickets({
    required String eventUid,
    required List<TicketPurchaseLine> lines,
  }) async {
    final validLines = lines.where((l) => l.quantity > 0).toList();
    if (validLines.isEmpty) {
      return const ApiResponse(data: null);
    }

    final response = await _networkService.post(
      ApiRoute.ticketsPurchase,
      data: {
        "event_uid": eventUid,
        "tickets": validLines.map((line) => line.toJson()).toList(),
      },
    );
    final root = response.data as Map<String, dynamic>;
    final payload = root["data"];
    if (payload is! Map<String, dynamic>) {
      return const ApiResponse(data: null);
    }
    return ApiResponse(data: SubscriptionPurchaseInit.fromJson(payload));
  }

  @override
  Future<ApiResponse<void>> verifyPayment({required String reference}) async {
    await _networkService.get(ApiRoute.paymentVerify(reference));
    return const ApiResponse();
  }
}

final ticketsRepositoryProvider = Provider<TicketsRepo>((ref) {
  return TicketsRepoImpl(networkService: ref.read(networkServiceProvider));
});
