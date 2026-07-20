import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SponsorshipsRepoImpl implements SponsorshipsRepo {
  SponsorshipsRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<ApiResponse<SponsorshipsData>> fetchSponsorships() async {
    final response = await _networkService.get(ApiRoute.sponsorships);
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      return const ApiResponse(data: SponsorshipsData.empty);
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      return const ApiResponse(data: SponsorshipsData.empty);
    }
    return ApiResponse(data: SponsorshipsData.fromJson(data));
  }
}

final sponsorshipsRepositoryProvider = Provider<SponsorshipsRepo>((ref) {
  return SponsorshipsRepoImpl(networkService: ref.read(networkServiceProvider));
});
