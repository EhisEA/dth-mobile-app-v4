import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class BannersViewModel extends BaseChangeNotifierViewModel {
  BannersViewModel(this._bannersRepo);

  final BannersRepo _bannersRepo;

  List<BannerModel> _banners = const [];
  List<BannerModel> get banners => _banners;

  Future<void> loadBanners() async {
    try {
      _banners = await _bannersRepo.fetchBanners();
      notifyListeners();
    } on ApiFailure {
      // Background fetch on home — fail silently. The strip is optional
      // and the UI degrades when [banners] stays empty.
    }
  }
}

final bannersViewModelProvider = ChangeNotifierProvider<BannersViewModel>((
  ref,
) {
  return BannersViewModel(ref.read(bannersRepositoryProvider));
});
