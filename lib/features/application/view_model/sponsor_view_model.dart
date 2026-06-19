import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SponsorViewModel extends BaseChangeNotifierViewModel {
  SponsorViewModel(this._sponsorRepo);

  final SponsorRepo _sponsorRepo;

  SponsorInfo? _sponsor;

  SponsorInfo? get sponsor => _sponsor;

  Future<void> load() async {
    try {
      final res = await _sponsorRepo.getSponsor();
      final info = res.data;
      _sponsor = info != null && info.isDisplayable ? info : null;
      _notifyIfMounted();
    } catch (_) {
      _sponsor = null;
      _notifyIfMounted();
    }
  }

  void _notifyIfMounted() {
    if (!hasListeners) return;
    notifyListeners();
  }
}

final sponsorViewModelProvider =
    ChangeNotifierProvider.autoDispose<SponsorViewModel>((ref) {
      return SponsorViewModel(ref.read(sponsorRepositoryProvider));
    });
