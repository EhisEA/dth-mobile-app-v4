import "dart:io";

import "package:dth_v4/core/provider.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:image_picker/image_picker.dart";

/// Personal information screen + in-app phone verification (send code, OTP entry,
/// resend timer). Keeps verification state until you finish or start a new send.
class PersonalInformationViewModel extends BaseChangeNotifierViewModel {
  PersonalInformationViewModel(
    this._profileRepo,
    this._userState,
    this._mediaService,
  ) : endTime = ValueNotifier<DateTime>(
        DateTime.now().add(const Duration(seconds: _defaultCooldownSeconds)),
      );

  static const int _defaultCooldownSeconds = 60;
  static const int _maxAvatarBytes = 2048 * 1024;
  static const int maxFullNameLength = 120;

  final ProfileRepo _profileRepo;
  final UserProfileState _userState;
  final MediaService _mediaService;

  final ValueNotifier<bool> canResend = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime> endTime;
  final ValueNotifier<bool> savingProfile = ValueNotifier<bool>(false);

  /// Full-page [Loader.page] should not cover the screen during profile save
  /// (that path uses [savingProfile] only).
  bool get isBlockingPageBusy => isBaseBusy && !savingProfile.value;

  String? _verificationSignature;
  String _phoneNumberForVerification = "";
  String _maskedPhoneForDisplay = "";

  String get maskedPhoneForDisplay => _maskedPhoneForDisplay;

  bool get hasActivePhoneVerification =>
      _verificationSignature != null &&
      _verificationSignature!.isNotEmpty &&
      _phoneNumberForVerification.isNotEmpty;

  /// Shown in the OTP subtitle (e.g. `+234 902 *** 19`).
  static String maskPhoneNumberForDisplay(String phoneNumber) {
    final raw = phoneNumber.trim();
    final d = raw.replaceAll(RegExp(r"\D"), "");
    if (d.length < 8) return raw;
    if (d.startsWith("234") && d.length >= 10) {
      final nsn = d.substring(3);
      if (nsn.length >= 3) {
        final last2 = d.substring(d.length - 2);
        return "+234 ${nsn.substring(0, 3)}***$last2";
      }
    }
    final last2 = d.substring(d.length - 2);
    final keep = (d.length - 5).clamp(4, 7);
    return "+${d.substring(0, keep)}***$last2";
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

  void clearPhoneVerificationSession() {
    _verificationSignature = null;
    _phoneNumberForVerification = "";
    _maskedPhoneForDisplay = "";
    notifyListeners();
  }

  /// Sends an SMS code and stores everything needed for the OTP step.
  Future<bool> sendPhoneVerificationCode(String phoneNumber) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Phone number",
        message: "Add a phone number before verifying.",
      );
      return false;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _profileRepo.sendPhoneOtp(
        phone: trimmed,
        channel: "text",
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
      _verificationSignature = sig;
      _phoneNumberForVerification = trimmed;
      _maskedPhoneForDisplay = maskPhoneNumberForDisplay(trimmed);
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

  Future<void> resendPhoneVerificationCode() async {
    if (isBaseBusy) return;
    final phone = _phoneNumberForVerification;
    if (phone.isEmpty || _verificationSignature == null) {
      DthFlushBar.instance.showError(
        title: "Resend code",
        message:
            "Your verification session expired. Go back and tap Verify again.",
      );
      return;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _profileRepo.sendPhoneOtp(
        phone: phone,
        channel: "text",
      );
      changeBaseState(const ViewModelState.idle());
      final newSig = response.data;
      if (newSig != null && newSig.isNotEmpty) {
        _verificationSignature = newSig;
      }
      DthFlushBar.instance.showSuccess(
        title: "Code sent",
        message: "A new verification code is on its way.",
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

  Future<bool> submitPhoneVerificationCode(String code) async {
    if (isBaseBusy) return false;
    final sig = _verificationSignature;
    if (sig == null || sig.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Verification",
        message:
            "We could not find an active code request. Go back and tap Verify again.",
      );
      return false;
    }
    try {
      changeBaseState(const ViewModelState.busy());
      await _profileRepo.verifyPhoneOtp(token: code, signature: sig);
      await _userState.getUserDetails();
      clearPhoneVerificationSession();
      changeBaseState(const ViewModelState.idle());
      return true;
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Verification failed",
      );
      return false;
    }
  }

  /// Updates `full_name`, `phone`, and `iso_code` together (multipart profile PUT).
  Future<bool> saveProfileDetails({
    required String fullName,
    required String phone,
    required String isoCode,
  }) async {
    final name = fullName.trim();
    if (name.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Name",
        message: "Please enter your full name.",
      );
      return false;
    }
    if (name.length > maxFullNameLength) {
      DthFlushBar.instance.showError(
        title: "Name",
        message:
            "That name is too long. Please use $maxFullNameLength characters or fewer.",
      );
      return false;
    }
    final phoneTrimmed = phone.trim();
    if (phoneTrimmed.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Phone",
        message: "Please enter your phone number.",
      );
      return false;
    }
    final current = _userState.user.value;
    if (current != null &&
        name == current.fullName.trim() &&
        phoneTrimmed == current.phoneNumber.trim() &&
        isoCode == current.isoCode) {
      return true;
    }
    try {
      savingProfile.value = true;
      notifyListeners();
      final response = await _profileRepo.updateProfile(
        fullName: name,
        phone: phoneTrimmed,
        isoCode: isoCode,
      );
      final updated = response.data;
      if (updated == null) {
        savingProfile.value = false;
        notifyListeners();
        DthFlushBar.instance.showError(
          title: "Update failed",
          message: "We could not save your profile. Please try again.",
        );
        return false;
      }
      await _userState.updateUserData(updated);
      DthFlushBar.instance.showSuccess(
        title: "Profile",
        message: "Your profile was updated.",
      );
      savingProfile.value = false;
      notifyListeners();
      return true;
    } on ApiFailure catch (e) {
      savingProfile.value = false;
      notifyListeners();
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Update failed",
      );
      return false;
    }
  }

  /// Picks an image from the gallery, enforces max size, uploads as `avatar`, refreshes user.
  ///
  /// Uses [ImagePicker] directly so we do not depend on [MediaService.getImage]'s
  /// `Permission.photos` pre-check (fails on iOS when access is "limited", which is
  /// not treated as [PermissionStatus.granted]).
  Future<void> pickAndUpdateProfileAvatar(UserModel current) async {
    if (isBaseBusy) return;

    if (kIsWeb) {
      DthFlushBar.instance.showError(
        title: "Photo",
        message: "Profile photo upload is not available on web.",
      );
      return;
    }

    final XFile? xfile;
    try {
      xfile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      DthFlushBar.instance.showError(
        title: "Photo access",
        message: e.message?.isNotEmpty == true
            ? e.message!
            : "Allow photo access in Settings to choose a profile picture.",
      );
      return;
    } catch (_) {
      DthFlushBar.instance.showError(
        title: "Photo",
        message: "Could not open the photo library. Please try again.",
      );
      return;
    }

    if (xfile == null) return;

    var path = xfile.path;
    var length = File(path).lengthSync();
    if (length > _maxAvatarBytes) {
      for (
        var quality = 85;
        quality >= 40 && length > _maxAvatarBytes;
        quality -= 15
      ) {
        try {
          final compressed = await _mediaService.compressImage(
            file: FileResult(path: path),
            quality: quality,
          );
          path = compressed.path;
          length = File(path).lengthSync();
        } catch (_) {
          break;
        }
      }
    }

    if (length > _maxAvatarBytes) {
      DthFlushBar.instance.showError(
        title: "Photo too large",
        message: "Please choose an image under 2 MB.",
      );
      return;
    }

    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _profileRepo.updateProfile(
        fullName: current.fullName,
        phone: current.phoneNumber,
        isoCode: current.isoCode,
        avatarFilePath: path,
      );
      final updated = response.data;
      if (updated != null) {
        _userState.setUser(updated);
        DthFlushBar.instance.showSuccess(
          title: "Profile photo",
          message: "Your profile photo was updated.",
        );
      }
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(
        message: e.message,
        title: "Update failed",
      );
    }
  }

  @override
  void dispose() {
    canResend.dispose();
    endTime.dispose();
    savingProfile.dispose();
    super.dispose();
  }
}

final personalInformationViewModelProvider =
    ChangeNotifierProvider<PersonalInformationViewModel>((ref) {
      return PersonalInformationViewModel(
        ref.read(profileRepositoryProvider),
        ref.read(userStateProvider),
        ref.read(mediaServiceProvider),
      );
    });
