import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class TicketsRepoImpl implements TicketsRepo {
  TicketsRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<ApiResponse<SubscriptionPurchaseInit>> purchaseTickets({
    required String eventUid,
    required String seatTypeUid,
    int quantity = 1,
  }) async {
    final response = await _networkService.post(
      ApiRoute.ticketsPurchase,
      data: {"event_uid": eventUid, "seat_type_uid": seatTypeUid, "quantity": quantity},
    );
    final root = response.data as Map<String, dynamic>;
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      return const ApiResponse(data: null);
    }
    return ApiResponse(data: SubscriptionPurchaseInit.fromJson(data));
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
