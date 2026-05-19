import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/bottomNavBar/viewmodel/phone_verification_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showPhoneVerificationBottomSheet(
  BuildContext context, {
  required UserModel user,
}) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    useSafeArea: false,
    builder: (ctx) => _PhoneVerificationSheetBody(user: user),
  );
}

class _PhoneVerificationSheetBody extends ConsumerStatefulWidget {
  const _PhoneVerificationSheetBody({required this.user});

  final UserModel user;

  @override
  ConsumerState<_PhoneVerificationSheetBody> createState() =>
      _PhoneVerificationSheetBodyState();
}

class _PhoneVerificationSheetBodyState
    extends ConsumerState<_PhoneVerificationSheetBody> {
  late final PhoneVerificationViewModel _vm;
  late final TextEditingController _phoneController;
  late final FocusNode _phoneFocus;
  late final TextEditingController _otpController;
  late final FocusNode _otpFocus;
  bool _didPrefillPhone = false;

  @override
  void initState() {
    super.initState();
    _vm = PhoneVerificationViewModel(
      ref.read(profileRepositoryProvider),
      ref.read(userProfileStateProvider),
      ref.read(deviceInfoStateProvider),
    );
    _vm.addListener(_onVmChanged);
    _phoneController = TextEditingController();
    _phoneFocus = FocusNode();
    _otpController = TextEditingController();
    _otpFocus = FocusNode();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
    if (_vm.step == PhoneVerificationStep.otpEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocus.requestFocus();
      });
    }
  }

  void _onPhoneChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _phoneFocus.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _prefillPhone(DthCountry ngCountry) {
    final stored = widget.user.phoneNumber.trim();
    if (stored.isEmpty) return;
    _phoneController.text = displayNationalPhoneInField(
      storedPhone: stored,
      country: ngCountry,
    );
  }

  bool _canSubmitPhone(DthCountry? ngCountry) {
    if (ngCountry == null) return false;
    return validateNationalPhone(_phoneController.text, ngCountry) == null;
  }

  bool get _hasStoredPhone => widget.user.phoneNumber.trim().isNotEmpty;

  Future<void> _onSendOtp(DthCountry ngCountry) async {
    if (!_canSubmitPhone(ngCountry) || _vm.isBaseBusy) return;
    HapticFeedback.lightImpact();
    final phone = composeInternationalPhone(
      country: ngCountry,
      nationalInput: _phoneController.text,
    );
    await _vm.submitPhone(isoCode: "NG", phoneE164: phone);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final ngCountry = ref
        .watch(countriesListProvider)
        .maybeWhen(
          data: (countries) => DthCountry.findByIso(countries, "NG"),
          orElse: () => null,
        );

    if (!_didPrefillPhone &&
        ngCountry != null &&
        _vm.step == PhoneVerificationStep.phoneEntry) {
      _didPrefillPhone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _prefillPhone(ngCountry);
      });
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: switch (_vm.step) {
          PhoneVerificationStep.phoneEntry => _buildPhoneEntry(ngCountry),
          PhoneVerificationStep.otpEntry => _buildOtpEntry(ngCountry),
          PhoneVerificationStep.success => _buildSuccess(),
        },
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 43,
        height: 4,
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: AppColors.greyTint20,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _headerIcon() {
    return Center(
      child: Image.asset(ImageAssets.phoneVerify, width: 83, height: 73),
    );
  }

  Widget _buildPhoneEntry(DthCountry? ngCountry) {
    final canSubmit = _canSubmitPhone(ngCountry);
    final subtitle = _hasStoredPhone
        ? "Verify your phone number to protect your account and receive important notifications."
        : "Add your phone number to protect your account and receive important notifications.";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetHandle(),
        _headerIcon(),
        Gap.h8,
        AppText.medium(
          "Complete Your Profile",
          fontSize: 18,
          color: AppColors.mainBlack,
          textAlign: TextAlign.center,
        ),
        Gap.h8,
        AppText.regular(
          subtitle,
          fontSize: 14,
          color: AppColors.tint25,
          textAlign: TextAlign.center,
          multiText: true,
        ),
        Gap.h24,
        if (ngCountry == null)
          const Center(child: CircularProgressIndicator.adaptive())
        else
          PhoneNumberCountryInput(
            controller: _phoneController,
            focusNode: _phoneFocus,
            displayCountry: ngCountry,
            lockCountryPicker: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSendOtp(ngCountry),
            validator: (v) => validateNationalPhone(v, ngCountry),
          ),
        Gap.h24,
        AppButton.primary(
          text: canSubmit ? "Send OTP" : "Complete form to continue",
          height: 52,
          disableBGColor: AppColors.greyTint20,
          enabled: canSubmit && ngCountry != null && !_vm.isBaseBusy,
          isLoading: _vm.isBaseBusy,
          press: canSubmit && ngCountry != null
              ? () => unawaited(_onSendOtp(ngCountry))
              : null,
        ),
        Gap.h12,
      ],
    );
  }

  Widget _buildOtpEntry(DthCountry? ngCountry) {
    final masked = _vm.maskedPhoneForDisplay;
    final otpErr = _vm.otpError;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetHandle(),
        _headerIcon(),
        Gap.h8,
        AppText.medium(
          "Enter Verification Code",
          fontSize: 18,
          color: AppColors.mainBlack,
          textAlign: TextAlign.center,
        ),
        Gap.h8,
        AppText.regular(
          "We sent a 6-digit code to $masked",
          fontSize: 12,
          color: AppColors.tint15,
          textAlign: TextAlign.center,
          multiText: true,
        ),
        Gap.h24,
        PinCodeField(
          otpController: _otpController,
          length: 6,
          width: 48,
          height: 52,
          focusnode: _otpFocus,
          enabled: !_vm.isBaseBusy,
          onChanged: (_) => _vm.clearOtpError(),
          onCompleted: (code) async {
            if (_vm.isBaseBusy) return;
            final ok = await _vm.verifyOtp(code);
            if (!mounted || !ok) return;
            _otpController.clear();
          },
        ),
        if (otpErr != null && otpErr.isNotEmpty) ...[
          Gap.h12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error, size: 16, color: AppColors.redTint35),
              Gap.w6,
              Expanded(
                child: AppText.regular(
                  otpErr,
                  fontSize: 12,
                  color: AppColors.redTint35,
                  multiText: true,
                ),
              ),
            ],
          ),
          Gap.h8,
          AppButton.primary(
            text: "Resend code",
            height: 52,
            disableBGColor: AppColors.greyTint20,
            isLoading: _vm.isBaseBusy,
            enabled: ngCountry != null && !_vm.isBaseBusy,
            press: () {
              HapticFeedback.lightImpact();
              unawaited(_vm.resendOtp(isoCode: "NG"));
              _otpController.clear();
              _otpFocus.requestFocus();
            },
          ),
        ] else ...[
          Gap.h16,
          ValueListenableBuilder<bool>(
            valueListenable: _vm.canResend,
            builder: (context, allowResend, _) {
              if (allowResend) {
                return Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _vm.isBaseBusy || ngCountry == null
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
                            await _vm.resendOtp(isoCode: "NG");
                            _otpController.clear();
                            _otpFocus.requestFocus();
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.regular(
                          "Didn't receive the code?",
                          fontSize: 12,
                          color: const Color(0xff6A6A6A),
                        ),
                        Gap.w2,
                        AppText.medium(
                          "Resend code",
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ValueListenableBuilder<DateTime>(
                valueListenable: _vm.endTime,
                builder: (context, value, _) {
                  return Center(
                    child: AuthCountDownWidget(
                      endTime: value,
                      onEnd: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _vm.onTimerEnd();
                        });
                      },
                      onResend: true,
                    ),
                  );
                },
              );
            },
          ),
          Gap.h16,
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetHandle(),
        Center(
          child: SvgPicture.asset(SvgAssets.phoneVerify, width: 83, height: 73),
        ),
        Gap.h8,
        AppText.medium(
          "Phone Number Verified",
          fontSize: 18,
          color: AppColors.mainBlack,
          textAlign: TextAlign.center,
        ),
        Gap.h8,
        AppText.regular(
          "Your phone number has been successfully verified.",
          fontSize: 12,
          color: AppColors.tint25,
          textAlign: TextAlign.center,
          multiText: true,
        ),
        Gap.h32,
        AppButton.primary(
          text: "Continue to timeline",
          press: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        Gap.h12,
      ],
    );
  }
}
