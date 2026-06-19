import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class BannersRepoImpl implements BannersRepo {
  BannersRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<List<BannerModel>> fetchBanners() async {
    final response = await _networkService.get(ApiRoute.banners);
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      return const [];
    }
    final data = root["data"];
    if (data is! List<dynamic>) {
      return const [];
    }
    return data
        .whereType<Map>()
        .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.imageUrl.trim().isNotEmpty)
        .toList(growable: false);
  }
}

final bannersRepositoryProvider = Provider<BannersRepo>((ref) {
  return BannersRepoImpl(networkService: ref.read(networkServiceProvider));
});
