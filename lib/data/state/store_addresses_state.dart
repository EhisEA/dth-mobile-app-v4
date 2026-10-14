import "package:dth_v4/core/extension/view_model_state.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Cached delivery addresses for checkout (avoid refetch on every sheet open).
class StoreAddressesState extends ChangeNotifier {
  StoreAddressesState(this._repo);

  final StoreRepo _repo;

  List<StoreCheckoutAddress> _addresses = const [];
  ViewModelState _loadState = const ViewModelState.idle();
  bool _loaded = false;

  List<StoreCheckoutAddress> get addresses => _addresses;
  ViewModelState get loadState => _loadState;
  bool get hasLoaded => _loaded;

  /// Fetches only when cold (or [force]). [quiet] skips the busy shimmer state.
  Future<void> fetchAddresses({bool force = false, bool quiet = false}) async {
    if (!force && _loaded) return;
    if (_loadState.isBusy) return;

    if (!quiet || !_loaded) {
      _loadState = const ViewModelState.busy();
      notifyListeners();
    }

    try {
      final list = await _repo.getAddresses();
      _addresses = list;
      _loaded = true;
      _loadState = const ViewModelState.idle();
      notifyListeners();
    } on ApiFailure catch (e) {
      _loadState = ViewModelState.error(e);
      notifyListeners();
    } catch (e) {
      _loadState = ViewModelState.error(ApiFailure(e.toString()));
      notifyListeners();
    }
  }

  /// Re-fetch in the background after add / update / delete.
  Future<void> refreshQuiet() => fetchAddresses(force: true, quiet: true);

  void removeLocally(String addressUid) {
    _addresses = _addresses
        .where((a) => a.uid != addressUid)
        .toList(growable: false);
    notifyListeners();
  }

  void clear() {
    _addresses = const [];
    _loaded = false;
    _loadState = const ViewModelState.idle();
    notifyListeners();
  }
}

final storeAddressesStateProvider =
    ChangeNotifierProvider<StoreAddressesState>((ref) {
      return StoreAddressesState(ref.read(storeRepositoryProvider));
    });
