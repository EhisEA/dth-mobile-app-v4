import "package:dth_v4/data/data.dart";

abstract class BannersRepo {
  Future<List<BannerModel>> fetchBanners();
}
