import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/data.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_utils/flutter_utils.dart';

class VerifyOtpViewModel extends BaseChangeNotifierViewModel {
  VerifyOtpViewModel(
    this._authRepo,
    this._userState,
    this._initialEmail,
    this.deviceInfoState,
  ) : endTime = ValueNotifier<DateTime>(
        DateTime.now().add(const Duration(seconds: _defaultCooldownSeconds)),
      );

  static const int _defaultCooldownSeconds = 60;

  final AuthRepo _authRepo;
  final UserProfileState _userState;
  final String _initialEmail;
  final DeviceInfoState deviceInfoState;

  final ValueNotifier<bool> canResend = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime> endTime;

  String _email = '';
  String? _otpSignature;
  String _otpFlow = OtpFlowArg.register;

  String get email => _email;
  String? get registrationSignature => _otpSignature;

  bool get _isLoginFlow => _otpFlow == OtpFlowArg.login;

  void hydrate({String? signature, String? otpFlow, int? ttlSeconds}) {
    _email = _initialEmail.trim();
    _otpSignature = (signature != null && signature.isNotEmpty)
        ? signature
        : null;
    _otpFlow = otpFlow == OtpFlowArg.login
        ? OtpFlowArg.login
        : OtpFlowArg.register;
    assignEndTime(ttlSeconds: ttlSeconds);
    notifyListeners();
  }

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

  String? _resendPreconditionMessage() {
    if (_email.isEmpty) {
      return 'Missing email. Go back and start again.';
    }
    if (_otpSignature == null || _otpSignature!.isEmpty) {
      if (_isLoginFlow) {
        return 'Start sign-in again from the login screen.';
      }
      return 'Go back and complete sign-up to request a new code.';
    }
    return null;
  }

  Future<String?> resendRegistrationOtp() async {
    final deviceName = await deviceInfoState.getDeviceName();
    final response = await _authRepo.resendRegisterOtp(
      email: _email,
      deviceName: deviceName,
    );
    return response.data?.signature;
  }

  Future<String?> resendLoginOtp() async {
    final deviceName = await deviceInfoState.getDeviceName();
    final response = await _authRepo.resendLoginOtp(
      email: _email,
      deviceName: deviceName,
    );
    return response.data?.signature;
  }

  Future<void> resendOtp() async {
    if (isBaseBusy) return;

    final block = _resendPreconditionMessage();
    if (block != null) {
      DthFlushBar.instance.showError(title: 'Resend code', message: block);
      return;
    }

    try {
      changeBaseState(const ViewModelState.busy());
      final newSignature = _isLoginFlow
          ? await resendLoginOtp()
          : await resendRegistrationOtp();
      changeBaseState(const ViewModelState.idle());
      DthFlushBar.instance.showSuccess(
        title: 'Success',
        message: 'Code resent successfully',
      );

      if (newSignature != null && newSignature.isNotEmpty) {
        _otpSignature = newSignature;
        onOtpResentCooldown();
        notifyListeners();
      }
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(message: e.message, title: 'Failed');
    }
  }

  Future<bool> submitOtp(String code) async {
    if (isBaseBusy) return false;
    final sig = _otpSignature;
    if (sig == null || sig.isEmpty) {
      DthFlushBar.instance.showError(
        title: 'Verification',
        message:
            'No verification session found. Go back and request a new code.',
      );
      return false;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      final fcmToken = await PushNotificationService.getToken();
      final deviceName = await deviceInfoState.getDeviceName();
      if (_isLoginFlow) {
        await _authRepo.verifyLoginOtp(
          otp: code,
          signature: sig,
          fcmToken: fcmToken ?? "",
          deviceName: deviceName,
        );
      } else {
        await _authRepo.verifyRegisterOtp(
          otp: code,
          signature: sig,
          fcmToken: fcmToken ?? "",
        );
      }
      await _userState.getUserDetails();
      changeBaseState(const ViewModelState.idle());
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(message: e.message, title: 'Failed');
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

final verifyOtpViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<VerifyOtpViewModel, String>((ref, initialEmail) {
      return VerifyOtpViewModel(
        ref.read(authRepositoryProvider),
        ref.read(userStateProvider),
        initialEmail,
        ref.read(deviceInfoStateProvider),
      );
    });
