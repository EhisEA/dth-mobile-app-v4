import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SponsorshipsViewModel extends BaseChangeNotifierViewModel {
  SponsorshipsViewModel(this._repo);

  final SponsorshipsRepo _repo;

  SponsorshipsData _data = SponsorshipsData.empty;
  SponsorshipsData get data => _data;

  SponsorshipSection? get voting => _data.voting;

  SponsorshipSection? get poll => _data.poll;

  Future<void> load() async {
    try {
      final res = await _repo.fetchSponsorships();
      _data = res.data ?? SponsorshipsData.empty;
      notifyListeners();
    } on ApiFailure {
      // Background fetch — fail silently. Footer hides when empty.
    }
  }
}

final sponsorshipsViewModelProvider =
    ChangeNotifierProvider<SponsorshipsViewModel>((ref) {
      return SponsorshipsViewModel(ref.read(sponsorshipsRepositoryProvider));
    });
