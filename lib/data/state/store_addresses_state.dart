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
  StoreShippingAddress? _shippingAddress;

  /// Bumped by [clear] so a fetch still running at logout cannot write the
  /// previous account's addresses back.
  int _generation = 0;

  List<StoreCheckoutAddress> get addresses => _addresses;
  ViewModelState get loadState => _loadState;
  bool get hasLoaded => _loaded;

  /// Address chosen for Merch Store delivery; sent as `address_uid` on quote.
  StoreShippingAddress? get shippingAddress => _shippingAddress;

  /// Fetches only when cold (or [force]). [quiet] skips the busy shimmer state.
  Future<void> fetchAddresses({bool force = false, bool quiet = false}) async {
    if (!force && _loaded) return;
    if (_loadState.isBusy) return;
    final generation = _generation;

    if (!quiet || !_loaded) {
      _loadState = const ViewModelState.busy();
      notifyListeners();
    }

    try {
      final list = await _repo.getAddresses();
      if (generation != _generation) return;
      _addresses = list;
      _loaded = true;
      _loadState = const ViewModelState.idle();
      notifyListeners();
    } on ApiFailure catch (e) {
      if (generation != _generation) return;
      _loadState = ViewModelState.error(e);
      notifyListeners();
    } catch (e) {
      if (generation != _generation) return;
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

  void setShippingAddress(StoreShippingAddress? address) {
    _shippingAddress = address;
    notifyListeners();
  }

  void clear() {
    _generation++;
    _addresses = const [];
    _shippingAddress = null;
    _loaded = false;
    _loadState = const ViewModelState.idle();
    notifyListeners();
  }
}

final storeAddressesStateProvider =
    ChangeNotifierProvider<StoreAddressesState>((ref) {
      return StoreAddressesState(ref.read(storeRepositoryProvider));
    });
