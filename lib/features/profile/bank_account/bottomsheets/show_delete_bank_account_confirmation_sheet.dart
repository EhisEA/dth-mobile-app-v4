import "dart:async";
import "dart:ui" show ImageFilter;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/profile/bank_account/view_model/bank_account_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showDeleteBankAccountConfirmationSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final sheetCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: animation,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ref
                          .read(bankAccountViewModelProvider)
                          .clearDeleteSession();
                      Navigator.of(dialogContext).pop();
                    },
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          color: const Color(0xff044423).withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(sheetCurve),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const _DeleteBankAccountOtpSheet(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    ref.read(bankAccountViewModelProvider).clearDeleteSession();
  });
}

class _DeleteBankAccountOtpSheet extends ConsumerStatefulWidget {
  const _DeleteBankAccountOtpSheet();

  @override
  ConsumerState<_DeleteBankAccountOtpSheet> createState() =>
      _DeleteBankAccountOtpSheetState();
}

class _DeleteBankAccountOtpSheetState
    extends ConsumerState<_DeleteBankAccountOtpSheet> {
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = ref.read(bankAccountViewModelProvider);
      if (!vm.hasActiveDeleteRequest) {
        DthFlushBar.instance.showError(
          title: "Verification",
          message: "Start again and request a code to continue.",
        );
        Navigator.of(context).maybePop();
        return;
      }
      _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    final code = _otpController.text.trim();
    final ok = await ref
        .read(bankAccountViewModelProvider)
        .confirmBankAccountDelete(code);
    if (!mounted || !ok) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(bankAccountViewModelProvider);
    final email = ref.watch(userStateProvider).user.value?.email ?? "";
    final masked = email.isEmpty
        ? "your email"
        : BankAccountViewModel.maskEmailForDisplay(email);

    return SafeArea(
      bottom: false,
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: vm.isBaseBusy
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: AppColors.greyTint15,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppColors.greyTint55,
                    ),
                  ),
                ),
              ],
            ),
            Gap.h16,
            AppText.medium(
              "Let's verify its you",
              fontSize: 22,
              centered: true,
              color: AppColors.tertiary60,
            ),
            Gap.h12,
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.tint25,
                ),
                children: [
                  const TextSpan(
                    text: "Enter the 6-digit code sent to your email ",
                  ),
                  TextSpan(
                    text: masked,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            Gap.h28,
            PinCodeField(
              otpController: _otpController,
              length: 6,
              width: 48,
              height: 52,
              focusnode: _otpFocusNode,
              enabled: !vm.isBaseBusy,
              onCompleted: (_) => unawaited(_submit()),
            ),
            Gap.h16,
            ValueListenableBuilder<bool>(
              valueListenable: vm.canResend,
              builder: (context, allowResend, _) {
                if (allowResend) {
                  return Row(
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
                                await vm.resendBankAccountDeleteOtp();
                                _otpController.clear();
                                _otpFocusNode.requestFocus();
                              },
                        child: AppText.medium(
                          "Resend code",
                          fontSize: 12,
                          color: AppColors.primary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  );
                }
                return ValueListenableBuilder<DateTime>(
                  valueListenable: vm.endTime,
                  builder: (context, value, _) {
                    return AuthCountDownWidget(
                      endTime: value,
                      onEnd: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ref
                                .read(bankAccountViewModelProvider)
                                .onTimerEnd();
                          }
                        });
                      },
                      onResend: true,
                    );
                  },
                );
              },
            ),
            Gap.h24,
            AppButton(
              text: "Submit",
              color: AppColors.redTint35,
              textColor: Colors.white,
              disableBGColor: AppColors.redTint35.withValues(alpha: 0.35),
              disableTextColor: Colors.white70,
              enabled: !vm.isBaseBusy,
              isLoading: vm.isBaseBusy,
              press: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
