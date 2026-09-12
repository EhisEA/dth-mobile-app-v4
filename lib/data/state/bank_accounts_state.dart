import "dart:async";

import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class BankAccountsState extends BaseState {
  BankAccountsState(this._profileRepo);

  final ProfileRepo _profileRepo;

  final ValueNotifier<List<BankAccount>> accounts =
      ValueNotifier<List<BankAccount>>(const []);

  bool get hasBankAccounts => accounts.value.isNotEmpty;

  Future<void> load() => _fetch();

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final response = await _profileRepo.getBankAccounts();
      accounts.value = response.data ?? const [];
    } on Failure {
      rethrow;
    } catch (e, st) {
      handleError(e, st);
      rethrow;
    }
  }

  @override
  void dispose() {
    accounts.dispose();
    super.dispose();
  }
}

final bankAccountsStateProvider = Provider<BankAccountsState>((ref) {
  final state = BankAccountsState(ref.read(profileRepositoryProvider));
  ref.onDispose(state.dispose);
  return state;
});
