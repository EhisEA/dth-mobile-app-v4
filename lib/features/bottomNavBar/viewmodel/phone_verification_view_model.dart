import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter_utils/flutter_utils.dart";

enum PhoneVerificationStep { phoneEntry, otpEntry, success }

class PhoneVerificationViewModel extends BaseChangeNotifierViewModel {
  PhoneVerificationViewModel(
    this._profileRepo,
    this._userState,
    this._deviceInfoState,
  ) : endTime = ValueNotifier<DateTime>(
        DateTime.now().add(const Duration(seconds: _defaultCooldownSeconds)),
      );

  static const int _defaultCooldownSeconds = 60;

  final ProfileRepo _profileRepo;
  final UserProfileState _userState;
  final DeviceInfoState _deviceInfoState;

  final ValueNotifier<bool> canResend = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime> endTime;

  PhoneVerificationStep step = PhoneVerificationStep.phoneEntry;
  String? _verificationSignature;
  String _phoneE164 = "";
  String _maskedPhoneForDisplay = "";
  String? otpError;

  String get maskedPhoneForDisplay => _maskedPhoneForDisplay;

  bool get hasActiveVerificationSession =>
      _verificationSignature != null && _verificationSignature!.isNotEmpty;

  static String maskPhoneNumberForDisplay(String phoneNumber) {
    final raw = phoneNumber.trim();
    final d = raw.replaceAll(RegExp(r"\D"), "");
    if (d.length < 8) return raw;
    if (d.startsWith("234") && d.length >= 10) {
      final nsn = d.substring(3);
      if (nsn.length >= 3) {
        final last2 = d.substring(d.length - 2);
        return "+234 ${nsn.substring(0, 3)} *** $last2";
      }
    }
    final last2 = d.substring(d.length - 2);
    final keep = (d.length - 5).clamp(4, 7);
    return "+${d.substring(0, keep)} *** $last2";
  }

  void assignEndTime({int? ttlSeconds}) {
    final seconds = ttlSeconds ?? _defaultCooldownSeconds;
    endTime.value = DateTime.now().add(Duration(seconds: seconds));
    canResend.value = false;
  }

  void onTimerEnd() {
    canResend.value = true;
  }

  void clearOtpError() {
    if (otpError == null) return;
    otpError = null;
    notifyListeners();
  }

  void _clearVerificationSession() {
    _verificationSignature = null;
    _phoneE164 = "";
    _maskedPhoneForDisplay = "";
    otpError = null;
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

  /// Submits phone; advances to OTP or success based on API `event`.
  Future<bool> submitPhone({
    required String isoCode,
    required String phoneE164,
  }) async {
    final phone = phoneE164.trim();
    if (phone.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Phone number",
        message: "Enter your phone number to continue.",
      );
      return false;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      otpError = null;
      final response = await _profileRepo.submitProfilePhone(
        isoCode: isoCode,
        phone: phone,
      );
      changeBaseState(const ViewModelState.idle());
      final result = response.data;
      if (result == null) {
        DthFlushBar.instance.showError(
          title: "Something went wrong",
          message: "We could not process your phone number. Please try again.",
        );
        return false;
      }

      if (result.requiresVerification) {
        final sig = result.signature;
        if (sig == null || sig.isEmpty) {
          DthFlushBar.instance.showError(
            title: "Something went wrong",
            message:
                "We could not start verification. Please try again in a moment.",
          );
          return false;
        }
        _verificationSignature = sig;
        _phoneE164 = phone;
        _maskedPhoneForDisplay = maskPhoneNumberForDisplay(phone);
        assignEndTime();
        step = PhoneVerificationStep.otpEntry;
        notifyListeners();
        return true;
      }

      await _userState.getUserDetailsFromServer();
      _clearVerificationSession();
      step = PhoneVerificationStep.success;
      notifyListeners();
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Could not continue",
      );
      return false;
    }
  }

  Future<void> resendOtp({required String isoCode}) async {
    if (isBaseBusy) return;
    final phone = _phoneE164;
    if (phone.isEmpty || !hasActiveVerificationSession) {
      DthFlushBar.instance.showError(
        title: "Resend code",
        message: "Enter your phone number and request a code first.",
      );
      return;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      otpError = null;
      final response = await _profileRepo.submitProfilePhone(
        isoCode: isoCode,
        phone: phone,
      );
      changeBaseState(const ViewModelState.idle());
      final result = response.data;
      if (result == null) {
        DthFlushBar.instance.showError(
          title: "Could not resend",
          message: "Please try again in a moment.",
        );
        return;
      }
      if (!result.requiresVerification) {
        await _userState.getUserDetailsFromServer();
        _clearVerificationSession();
        step = PhoneVerificationStep.success;
        notifyListeners();
        return;
      }
      final newSig = result.signature;
      if (newSig != null && newSig.isNotEmpty) {
        _verificationSignature = newSig;
      }
      assignEndTime();
      notifyListeners();
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Could not resend",
      );
    }
  }

  Future<bool> verifyOtp(String code) async {
    if (isBaseBusy) return false;
    final sig = _verificationSignature;
    if (sig == null || sig.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Verification",
        message: "Request a new code and try again.",
      );
      return false;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      otpError = null;
      final deviceName = await _optionalDeviceName();
      await _profileRepo.verifyPhoneOtp(
        token: code,
        signature: sig,
        deviceName: deviceName,
      );
      await _userState.getUserDetailsFromServer();
      _clearVerificationSession();
      changeBaseState(const ViewModelState.idle());
      step = PhoneVerificationStep.success;
      notifyListeners();
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      otpError = e.message.isNotEmpty
          ? e.message
          : "The code you entered is invalid. Please try again.";
      notifyListeners();
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
