import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SharesRepoImpl implements SharesRepo {
  SharesRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<void> recordShare({
    required String modelType,
    required String modelId,
  }) async {
    await _networkService.post(
      ApiRoute.shares,
      data: <String, dynamic>{"model_type": modelType, "model_id": modelId},
    );
  }
}

final sharesRepositoryProvider = Provider<SharesRepo>((ref) {
  return SharesRepoImpl(networkService: ref.read(networkServiceProvider));
});
