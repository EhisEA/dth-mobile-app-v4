import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/features/authentication/view_model/verify_otp_view_model.dart';
import 'package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_utils/flutter_utils.dart';

class VerifyOtpView extends ConsumerStatefulWidget {
  const VerifyOtpView({
    super.key,
    required this.email,
    this.signature,
    this.otpFlow,
    this.ttlSeconds,
  });

  static const String path = NavigatorRoutes.verifyOtp;

  final String email;
  final String? signature;
  final String? otpFlow;
  final int? ttlSeconds;

  @override
  ConsumerState<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends ConsumerState<VerifyOtpView> {
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(verifyOtpViewModelProvider(widget.email))
          .hydrate(
            signature: widget.signature,
            otpFlow: widget.otpFlow,
            ttlSeconds: widget.ttlSeconds,
          );
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

  Future<void> _handleResendOtp(VerifyOtpViewModel vm) async {
    HapticFeedback.lightImpact();
    await vm.resendOtp();
  }

  Future<void> _submitOtp(VerifyOtpViewModel vm, String code) async {
    final ok = await vm.submitOtp(code);
    if (mounted && ok) {
      MobileNavigationService.instance.navigateAndClearStack(BottomNavBar.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(verifyOtpViewModelProvider(widget.email));
    return Loader.page(
      isLoading: vm.isBaseBusy,
      child: Scaffold(
        appBar: const DthAppBar(title: ''),
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
                  "Let's verify its you",
                  fontSize: 22,
                  centered: true,
                  color: const Color(0xff08102F),
                ),
                Gap.h12,
                AppText.regular(
                  'Enter the 6-digit code sent to your email to continue',
                  fontSize: 14,
                  height: 1.4,
                  color: const Color(0xff454545),
                  centered: true,
                ),
                Gap.h28,
                PinCodeField(
                  otpController: _otpController,
                  length: 6,
                  width: 60,
                  height: 60,
                  title: 'OTP',
                  focusnode: _otpFocusNode,
                  onCompleted: (code) => _submitOtp(vm, code),
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
                                      : () => _handleResendOtp(vm),
                                  child: AppText.medium(
                                    resendLoading ? 'Sending…' : 'Resend Code',
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
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            ref
                                                .read(
                                                  verifyOtpViewModelProvider(
                                                    widget.email,
                                                  ),
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
