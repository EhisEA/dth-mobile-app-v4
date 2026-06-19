import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SponsorRepoImpl implements SponsorRepo {
  SponsorRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<ApiResponse<SponsorInfo?>> getSponsor() async {
    final response = await _networkService.get(ApiRoute.sponsor);
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      return const ApiResponse(data: null);
    }
    final data = root["data"];
    if (data == null) {
      return const ApiResponse(data: null);
    }
    if (data is! Map<String, dynamic>) {
      return const ApiResponse(data: null);
    }
    return ApiResponse(data: SponsorInfo.fromJson(data));
  }
}

final sponsorRepositoryProvider = Provider<SponsorRepo>((ref) {
  return SponsorRepoImpl(networkService: ref.read(networkServiceProvider));
});
