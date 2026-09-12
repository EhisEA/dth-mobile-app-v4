import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class WithdrawalViewModel extends BaseChangeNotifierViewModel {
  WithdrawalViewModel(
    this._profileRepo,
    this._bankAccountsState,
    this._userState,
  );

  final ProfileRepo _profileRepo;
  final BankAccountsState _bankAccountsState;
  final UserState _userState;

  int _amount = 0;
  int get amount => _amount;

  String? _selectedBankAccountUid;
  String? get selectedBankAccountUid => _selectedBankAccountUid;

  Withdrawal? _lastWithdrawal;
  Withdrawal? get lastWithdrawal => _lastWithdrawal;

  bool _banksLoading = false;
  bool get banksLoading => _banksLoading;

  String? _banksError;
  String? get banksError => _banksError;

  bool get banksReady => !_banksLoading && _banksError == null;

  List<BankAccount> get bankAccounts => _bankAccountsState.accounts.value;

  bool get hasBankAccounts => _bankAccountsState.hasBankAccounts;

  UserModel? get user => _userState.user.value;

  WalletBalance get walletBalance =>
      user?.walletBalance ?? const WalletBalance();

  WithdrawalLimit get withdrawalLimit =>
      user?.withdrawalLimit ??
      const WithdrawalLimit(minimum: 1, maximum: 1000000000);

  int get availableAmount {
    final digits = walletBalance.amount.replaceAll(RegExp(r"\D"), "");
    return int.tryParse(digits) ?? 0;
  }

  int get minWithdrawAmount => withdrawalLimit.minimum;

  /// Highest amount the user may withdraw right now (balance ∩ max limit).
  int get maxWithdrawableAmount {
    final cap = withdrawalLimit.maximum;
    if (availableAmount <= 0) return 0;
    return availableAmount < cap ? availableAmount : cap;
  }

  String get availableLabel => walletBalance.formattedLabel;

  String get formattedAmountDisplay =>
      _amount <= 0 ? "" : _amount.toMoneyWholeNumber();

  String get formattedAmountWithSymbol =>
      _amount <= 0 ? "₦0" : "₦${_amount.toMoneyWholeNumber()}";

  String get proceedCtaLabel =>
      "Proceed to withdraw $formattedAmountWithSymbol";

  String? get amountValidationMessage {
    if (_amount <= 0) return null;
    if (availableAmount < minWithdrawAmount) {
      return "Available balance is below the minimum withdrawal of ₦${minWithdrawAmount.toMoneyWholeNumber()}";
    }
    if (_amount < minWithdrawAmount) {
      return "Minimum withdrawal is ₦${minWithdrawAmount.toMoneyWholeNumber()}";
    }
    if (_amount > withdrawalLimit.maximum) {
      return "Maximum withdrawal is ₦${withdrawalLimit.maximum.toMoneyWholeNumber()}";
    }
    if (_amount > availableAmount) {
      return "Amount exceeds your available balance";
    }
    return null;
  }

  bool get canProceedAmount =>
      _amount >= minWithdrawAmount &&
      _amount <= maxWithdrawableAmount &&
      amountValidationMessage == null &&
      !isBaseBusy;

  bool get canSubmit {
    final uid = _selectedBankAccountUid?.trim() ?? "";
    return canProceedAmount && uid.isNotEmpty && !isBaseBusy;
  }

  void reset() {
    _amount = 0;
    _selectedBankAccountUid = null;
    _lastWithdrawal = null;
    _banksLoading = false;
    _banksError = null;
    changeBaseState(const ViewModelState.idle());
    notifyListeners();
  }

  Future<void> loadBankAccounts() async {
    _banksLoading = true;
    _banksError = null;
    notifyListeners();
    try {
      await _bankAccountsState.load();
      final accounts = bankAccounts;
      if (accounts.isNotEmpty) {
        BankAccount? preferred;
        for (final account in accounts) {
          if (account.isDefault) {
            preferred = account;
            break;
          }
        }
        _selectedBankAccountUid = preferred?.uid ?? accounts.first.uid;
      } else {
        _selectedBankAccountUid = null;
      }
      _banksError = null;
    } on ApiFailure catch (e) {
      _banksError = e.message;
    } catch (_) {
      _banksError = "Could not load bank accounts. Please try again.";
    } finally {
      _banksLoading = false;
      notifyListeners();
    }
  }

  void setAmountDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r"\D"), "");
    if (digits.isEmpty) {
      _amount = 0;
      notifyListeners();
      return;
    }
    var value = int.tryParse(digits) ?? 0;
    final maxAllowed = maxWithdrawableAmount;
    if (maxAllowed > 0 && value > maxAllowed) {
      value = maxAllowed;
    }
    _amount = value;
    notifyListeners();
  }

  void setMaxAmount() {
    _amount = maxWithdrawableAmount;
    notifyListeners();
  }

  void selectBankAccount(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty || trimmed == _selectedBankAccountUid) return;
    _selectedBankAccountUid = trimmed;
    notifyListeners();
  }

  Future<Withdrawal?> submit() async {
    if (!canSubmit) return null;
    final uid = _selectedBankAccountUid!.trim();
    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _profileRepo.createWithdrawal(
        amount: _amount,
        bankAccountUid: uid,
      );
      final withdrawal = response.data;
      if (withdrawal == null) {
        changeBaseState(const ViewModelState.idle());
        DthFlushBar.instance.showError(
          title: "Withdrawal",
          message: "Could not submit withdrawal. Please try again.",
        );
        return null;
      }
      _lastWithdrawal = withdrawal;
      try {
        await _userState.getUserDetails();
      } catch (_) {
        // Banner/wallet refresh is best-effort after a successful submit.
      }
      changeBaseState(const ViewModelState.idle());
      return withdrawal;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        title: "Could not withdraw",
        message: e.message,
      );
      return null;
    }
  }
}

final withdrawalViewModelProvider =
    ChangeNotifierProvider.autoDispose<WithdrawalViewModel>((ref) {
      return WithdrawalViewModel(
        ref.read(profileRepositoryProvider),
        ref.read(bankAccountsStateProvider),
        ref.read(userStateProvider),
      );
    });
