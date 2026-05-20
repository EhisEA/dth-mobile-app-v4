import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/authentication/views/get_started_view.dart";
import "package:dth_v4/features/profile/delete_account/view_model/delete_account_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class DeleteAccountOtpView extends ConsumerStatefulWidget {
  const DeleteAccountOtpView({super.key});

  static const String path = NavigatorRoutes.deleteAccountOtp;

  @override
  ConsumerState<DeleteAccountOtpView> createState() =>
      _DeleteAccountOtpViewState();
}

class _DeleteAccountOtpViewState extends ConsumerState<DeleteAccountOtpView> {
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = ref.read(deleteAccountViewModelProvider);
      if (!vm.hasActiveDeletionRequest) {
        DthFlushBar.instance.showError(
          title: "Verification",
          message: "Start from Delete account and request a code to continue.",
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
    final vm = ref.watch(deleteAccountViewModelProvider);

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
                  "Let's verify it's you",
                  fontSize: 22,
                  centered: true,
                  color: AppColors.tertiary60,
                ),
                Gap.h12,
                AppText.regular(
                  "Enter the 6-digit code sent to your email to continue.",
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
                  title: "Enter OTP",
                  focusnode: _otpFocusNode,
                  onCompleted: (code) async {
                    final successMessage = await vm.confirmDeletion(code);
                    if (!mounted || successMessage == null) return;
                    vm.clearDeletionSession();
                    await ref.read(userStateProvider).signOut();
                    if (!mounted) return;
                    MobileNavigationService.instance.navigateAndClearStack(
                      GetStartedView.path,
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      DthFlushBar.instance.showSuccess(
                        title: "Account deletion",
                        message: successMessage,
                        duration: const Duration(seconds: 6),
                      );
                    });
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
                                          await vm.resendDeletionCode();
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
                                    WidgetsBinding.instance.addPostFrameCallback(
                                      (_) {
                                        if (mounted) {
                                          ref
                                              .read(
                                                deleteAccountViewModelProvider,
                                              )
                                              .onTimerEnd();
                                        }
                                      },
                                    );
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
