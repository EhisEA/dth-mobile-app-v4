import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SupportRepoImpl implements SupportRepo {
  SupportRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<ApiResponse<SupportWebSession>> createSupportWebSession() async {
    final response = await _networkService.post(
      ApiRoute.supportWebSession,
      data: <String, dynamic>{},
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      return ApiResponse(data: const SupportWebSession(url: ""));
    }
    return ApiResponse(
      data: SupportWebSession.fromResponseRoot(Map<String, dynamic>.from(root)),
    );
  }
}

final supportRepositoryProvider = Provider<SupportRepo>((ref) {
  return SupportRepoImpl(networkService: ref.read(networkServiceProvider));
});
