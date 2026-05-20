import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/profile/personal_information/view_model/personal_information_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ProfilePhoneVerifyOtpView extends ConsumerStatefulWidget {
  const ProfilePhoneVerifyOtpView({super.key});

  static const String path = NavigatorRoutes.profilePhoneVerifyOtp;

  @override
  ConsumerState<ProfilePhoneVerifyOtpView> createState() =>
      _ProfilePhoneVerifyOtpViewState();
}

class _ProfilePhoneVerifyOtpViewState
    extends ConsumerState<ProfilePhoneVerifyOtpView> {
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = ref.read(personalInformationViewModelProvider);
      if (!vm.hasActivePhoneVerification) {
        DthFlushBar.instance.showError(
          title: "Verification",
          message:
              "Start from Personal Information and tap Verify to request a code.",
        );
        Navigator.of(context).maybePop();
        return;
      }
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(personalInformationViewModelProvider);
    final masked = vm.maskedPhoneForDisplay;

    return Loader.page(
      isLoading: vm.isBaseBusy,
      child: Scaffold(
        appBar: const DthAppBar(title: ""),
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gap.h16,
                AppText.medium(
                  "Verify your phone number",
                  fontSize: 22,
                  centered: true,
                  color: AppColors.tertiary60,
                ),
                Gap.h12,
                AppText.regular(
                  "Enter the 6-digit code sent to $masked to continue.",
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.tint25,
                  centered: true,
                ),
                Gap.h28,
                PinCodeField(
                  otpController: _otpController,
                  length: 6,
                  width: 60,
                  height: 60,
                  title: "OTP",
                  focusnode: _otpFocusNode,
                  onCompleted: (code) async {
                    final ok = await vm.submitPhoneVerificationCode(code);
                    if (!mounted || !ok) return;
                    MobileNavigationService.instance.goBack();
                  },
                ),
                Gap.h16,
                ValueListenableBuilder<bool>(
                  valueListenable: vm.canResend,
                  builder: (context, allowResend, _) {
                    final resendLoading = vm.isBaseBusy && allowResend;
                    return Center(
                      child: allowResend
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText.regular(
                                  "Didn't receive the code?",
                                  color: const Color(0xff6A6A6A),
                                  fontSize: 12,
                                  letterSpacing: -0.4,
                                ),
                                Gap.w2,
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: vm.isBaseBusy
                                      ? null
                                      : () async {
                                          HapticFeedback.lightImpact();
                                          await vm
                                              .resendPhoneVerificationCode();
                                        },
                                  child: AppText.medium(
                                    resendLoading ? "Sending…" : "Resend code",
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            )
                          : ValueListenableBuilder<DateTime>(
                              valueListenable: vm.endTime,
                              builder: (context, value, _) {
                                return AuthCountDownWidget(
                                  endTime: value,
                                  onEnd: () {
                                    WidgetsBinding.instance.addPostFrameCallback((
                                      _,
                                    ) {
                                      if (mounted) {
                                        ref
                                            .read(
                                              personalInformationViewModelProvider,
                                            )
                                            .onTimerEnd();
                                      }
                                    });
                                  },
                                  onResend: true,
                                );
                              },
                            ),
                    );
                  },
                ),
                Gap.h24,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
