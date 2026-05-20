import "package:dth_v4/core/services/push_notification_service.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class DeleteAccountViewModel extends BaseChangeNotifierViewModel {
  DeleteAccountViewModel(this._profileRepo, this._deviceInfoState)
    : endTime = ValueNotifier<DateTime>(
        DateTime.now().add(const Duration(seconds: _defaultCooldownSeconds)),
      );

  static const int _defaultCooldownSeconds = 60;

  final ProfileRepo _profileRepo;
  final DeviceInfoState _deviceInfoState;

  final ValueNotifier<bool> canResend = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime> endTime;

  bool _consentGiven = false;
  String? _deletionSignature;

  bool get consentGiven => _consentGiven;

  bool get hasActiveDeletionRequest =>
      _deletionSignature != null && _deletionSignature!.isNotEmpty;

  void setConsent(bool value) {
    if (_consentGiven == value) return;
    _consentGiven = value;
    notifyListeners();
  }

  void toggleConsent() => setConsent(!_consentGiven);

  void assignEndTime({int? ttlSeconds}) {
    final seconds = ttlSeconds ?? _defaultCooldownSeconds;
    endTime.value = DateTime.now().add(Duration(seconds: seconds));
    canResend.value = false;
  }

  void onTimerEnd() {
    canResend.value = true;
  }

  void onOtpResentCooldown() {
    assignEndTime(ttlSeconds: _defaultCooldownSeconds);
  }

  /// Clears in-memory deletion flow state (e.g. after success or abandoning the flow).
  void clearDeletionSession() {
    _deletionSignature = null;
    _consentGiven = false;
    canResend.value = false;
    assignEndTime(ttlSeconds: _defaultCooldownSeconds);
    notifyListeners();
  }

  /// Call when opening the delete-account intro so a prior abandoned session does not leak.
  void resetForNewFlow() {
    _deletionSignature = null;
    _consentGiven = false;
    canResend.value = false;
    assignEndTime(ttlSeconds: _defaultCooldownSeconds);
    notifyListeners();
  }

  Future<String?> _optionalDeviceName() async {
    try {
      final name = await _deviceInfoState.getDeviceName();
      final t = name.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestDeletionOtp() async {
    if (!_consentGiven) {
      DthFlushBar.instance.showError(
        title: "Consent required",
        message: "Please confirm you understand the conditions above.",
      );
      return false;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      final deviceName = await _optionalDeviceName();
      final response = await _profileRepo.requestAccountDeletion(
        deviceName: deviceName,
      );
      changeBaseState(const ViewModelState.idle());
      final sig = response.data;
      if (sig == null || sig.isEmpty) {
        DthFlushBar.instance.showError(
          title: "Something went wrong",
          message:
              "We could not send a verification code. Please try again in a moment.",
        );
        return false;
      }
      _deletionSignature = sig;
      assignEndTime();
      notifyListeners();
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Could not send code",
      );
      return false;
    }
  }

  Future<void> resendDeletionCode() async {
    if (isBaseBusy) return;
    if (!hasActiveDeletionRequest) {
      DthFlushBar.instance.showError(
        title: "Resend code",
        message:
            "Your verification session expired. Go back and request deletion again.",
      );
      return;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      final deviceName = await _optionalDeviceName();
      final response = await _profileRepo.requestAccountDeletion(
        deviceName: deviceName,
      );
      changeBaseState(const ViewModelState.idle());
      final newSig = response.data;
      if (newSig != null && newSig.isNotEmpty) {
        _deletionSignature = newSig;
      }
      DthFlushBar.instance.showSuccess(
        title: "Code sent",
        message: "A new verification code has been sent to your email.",
      );
      onOtpResentCooldown();
      notifyListeners();
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Could not resend",
      );
    }
  }

  static const String _defaultDeletionSuccessMessage =
      "Account will be deleted in 30 days. Log in to your account to cancel the deletion.";

  /// Returns the server message to show after sign-out, or `null` on failure.
  Future<String?> confirmDeletion(String token) async {
    if (isBaseBusy) return null;
    final sig = _deletionSignature;
    if (sig == null || sig.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Verification",
        message:
            "We could not find an active deletion request. Go back and try again.",
      );
      return null;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      final deviceName = await _optionalDeviceName();
      final fcmToken = await PushNotificationService.getToken();
      final response = await _profileRepo.confirmAccountDeletion(
        token: token,
        signature: sig,
        deviceName: deviceName,
        fcmToken: fcmToken,
      );
      changeBaseState(const ViewModelState.idle());
      final apiMessage = response.data?.trim();
      if (apiMessage != null && apiMessage.isNotEmpty) {
        return apiMessage;
      }
      return _defaultDeletionSuccessMessage;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Verification failed",
      );
      return null;
    }
  }

  @override
  void dispose() {
    canResend.dispose();
    endTime.dispose();
    super.dispose();
  }
}

final deleteAccountViewModelProvider =
    ChangeNotifierProvider<DeleteAccountViewModel>((ref) {
      return DeleteAccountViewModel(
        ref.read(profileRepositoryProvider),
        ref.read(deviceInfoStateProvider),
      );
    });
