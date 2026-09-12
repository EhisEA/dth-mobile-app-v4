import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class BankAccountViewModel extends BaseChangeNotifierViewModel {
  BankAccountViewModel(this._profileRepo, this._bankAccountsState)
    : endTime = ValueNotifier<DateTime>(
        DateTime.now().add(const Duration(seconds: _defaultCooldownSeconds)),
      );

  static const int _defaultCooldownSeconds = 60;

  final ProfileRepo _profileRepo;
  final BankAccountsState _bankAccountsState;

  final ValueNotifier<bool> canResend = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime> endTime;

  String? _deleteSignature;
  String? _pendingDeleteBankAccountUid;

  bool get hasActiveDeleteRequest =>
      _deleteSignature != null &&
      _deleteSignature!.isNotEmpty &&
      _pendingDeleteBankAccountUid != null &&
      _pendingDeleteBankAccountUid!.isNotEmpty;

  List<BankInstitution> _banks = const [];
  List<BankInstitution> get banks => _banks;

  bool _banksLoading = false;
  bool get banksLoading => _banksLoading;

  bool _resolving = false;
  bool get resolving => _resolving;

  static const String _listKey = "bankAccountsList";

  ViewModelState get listState =>
      getState(_listKey) ?? const ViewModelState.busy();

  Future<void> loadAccounts() async {
    try {
      setState(_listKey, const ViewModelState.busy());
      await _bankAccountsState.load();
      setState(_listKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      setState(_listKey, ViewModelState.error(e));
    }
  }

  Future<void> loadBanks({String? search}) async {
    _banksLoading = true;
    notifyListeners();
    try {
      final response = await _profileRepo.getBanks(search: search);
      _banks = response.data ?? const [];
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(title: "Banks", message: e.message);
    } finally {
      _banksLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resolveAccountName({
    required String bankUid,
    required String accountNumber,
  }) async {
    _resolving = true;
    notifyListeners();
    try {
      final response = await _profileRepo.resolveBankAccount(
        bankUid: bankUid,
        accountNumber: accountNumber,
      );
      return response.data;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(
        title: "Could not resolve account",
        message: e.message,
      );
      return null;
    } finally {
      _resolving = false;
      notifyListeners();
    }
  }

  Future<bool> addBankAccount({
    required String bankUid,
    required String accountNumber,
    required String accountName,
  }) async {
    if (isBaseBusy) return false;
    try {
      changeBaseState(const ViewModelState.busy());
      await _profileRepo.addBankAccount(
        bankUid: bankUid,
        accountNumber: accountNumber,
        accountName: accountName,
      );
      await _bankAccountsState.refresh();
      changeBaseState(const ViewModelState.idle());
      DthFlushBar.instance.showSuccess(
        title: "Bank account",
        message: "Your bank account was saved.",
      );
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        title: "Could not save",
        message: e.message,
      );
      return false;
    }
  }

  void assignEndTime({int? ttlSeconds}) {
    final seconds = ttlSeconds ?? _defaultCooldownSeconds;
    endTime.value = DateTime.now().add(Duration(seconds: seconds));
    canResend.value = false;
  }

  void onTimerEnd() {
    canResend.value = true;
  }

  void clearDeleteSession() {
    _deleteSignature = null;
    _pendingDeleteBankAccountUid = null;
    canResend.value = false;
    assignEndTime(ttlSeconds: _defaultCooldownSeconds);
    notifyListeners();
  }

  /// Masks `example@email.com` → `exam**ple@email.com`.
  static String maskEmailForDisplay(String email) {
    final trimmed = email.trim();
    final at = trimmed.indexOf("@");
    if (at <= 0) return trimmed;
    final local = trimmed.substring(0, at);
    final domain = trimmed.substring(at);
    if (local.length <= 4) {
      return "${local[0]}***$domain";
    }
    final tailLen = local.length >= 7 ? 3 : 2;
    return "${local.substring(0, 4)}**"
        "${local.substring(local.length - tailLen)}$domain";
  }

  Future<bool> requestBankAccountDeleteOtp(String bankAccountUid) async {
    if (isBaseBusy) return false;
    final uid = bankAccountUid.trim();
    if (uid.isEmpty) return false;
    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _profileRepo.requestBankAccountDeleteOtp(
        bankAccountUid: uid,
      );
      changeBaseState(const ViewModelState.idle());
      final session = response.data;
      if (session == null || session.signature.isEmpty) {
        DthFlushBar.instance.showError(
          title: "Something went wrong",
          message:
              "We could not send a verification code. Please try again in a moment.",
        );
        return false;
      }
      _pendingDeleteBankAccountUid = uid;
      _deleteSignature = session.signature;
      assignEndTime();
      notifyListeners();
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        title: "Could not send code",
        message: e.message,
      );
      return false;
    }
  }

  Future<void> resendBankAccountDeleteOtp() async {
    if (isBaseBusy) return;
    final uid = _pendingDeleteBankAccountUid?.trim() ?? "";
    if (uid.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Resend code",
        message:
            "Your verification session expired. Go back and try deleting again.",
      );
      return;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _profileRepo.requestBankAccountDeleteOtp(
        bankAccountUid: uid,
      );
      changeBaseState(const ViewModelState.idle());
      final session = response.data;
      if (session != null && session.signature.isNotEmpty) {
        _deleteSignature = session.signature;
        assignEndTime();
      }
      DthFlushBar.instance.showSuccess(
        title: "Code sent",
        message: "A new verification code has been sent to your email.",
      );
      notifyListeners();
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        title: "Could not resend",
        message: e.message,
      );
    }
  }

  Future<bool> confirmBankAccountDelete(String token) async {
    if (isBaseBusy) return false;
    final uid = _pendingDeleteBankAccountUid?.trim() ?? "";
    final sig = _deleteSignature?.trim() ?? "";
    final otp = token.trim();
    if (uid.isEmpty || sig.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Verification",
        message:
            "We could not find an active deletion request. Go back and try again.",
      );
      return false;
    }
    if (otp.length != 6) {
      DthFlushBar.instance.showError(
        title: "Verification",
        message: "Enter the 6-digit code sent to your email.",
      );
      return false;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      await _profileRepo.deleteBankAccount(
        bankAccountUid: uid,
        token: otp,
        signature: sig,
      );
      await _bankAccountsState.refresh();
      clearDeleteSession();
      changeBaseState(const ViewModelState.idle());
      DthFlushBar.instance.showSuccess(
        title: "Bank account",
        message: "Bank account deleted.",
      );
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        title: "Could not delete",
        message: e.message,
      );
      return false;
    }
  }

  @override
  void dispose() {
    canResend.dispose();
    endTime.dispose();
    super.dispose();
  }
}

final bankAccountViewModelProvider =
    ChangeNotifierProvider<BankAccountViewModel>((ref) {
      return BankAccountViewModel(
        ref.read(profileRepositoryProvider),
        ref.read(bankAccountsStateProvider),
      );
    });
