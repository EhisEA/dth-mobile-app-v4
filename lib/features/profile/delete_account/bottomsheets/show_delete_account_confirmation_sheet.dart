import "dart:ui" show ImageFilter;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/profile/delete_account/view_model/delete_account_view_model.dart";
import "package:dth_v4/features/profile/delete_account/views/delete_account_otp_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showDeleteAccountConfirmationSheet(
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
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          color: Color(0xff044423).withValues(alpha: 0.12),
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
                    child: Consumer(
                      builder: (context, ref2, _) {
                        final vm = ref2.watch(deleteAccountViewModelProvider);
                        return SafeArea(
                          bottom: false,
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(22, 22, 22, 16 + 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: const Color(0xffFFF8F4),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          SvgPicture.asset(
                                            SvgAssets.error,
                                            height: 32,
                                            width: 32,
                                          ),
                                          Gap.h8,
                                          AppText.bold(
                                            "ARE YOU SURE YOU WANT TO\nDELETE YOUR ACCOUNT?",
                                            fontSize: 12,
                                            color: AppColors.redTint35,
                                            centered: true,
                                            height: 1.25,
                                            letterSpacing: 0.4,
                                          ),
                                          Gap.h28,
                                          const _Bullet(
                                            text:
                                                "Deleting your account is a permanent action. You will lose access to all our services.",
                                          ),
                                          Gap.h12,
                                          const _Bullet(
                                            text:
                                                "Your account will be deactivated for 30 days before permanent deletion or anonymization.",
                                          ),
                                          Gap.h12,
                                          const _Bullet(
                                            text:
                                                "Your deletion request will be canceled if you log in before the 30-day grace period ends.",
                                          ),
                                          Gap.h12,
                                          const _Bullet(
                                            text:
                                                "Your transaction records will be retained for regulatory purposes.",
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: vm.isBaseBusy
                                            ? null
                                            : () => Navigator.of(
                                                dialogContext,
                                              ).pop(),
                                        child: Container(
                                          height: 24,
                                          width: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 12,
                                            color: AppColors.greyTint55,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Gap.h16,
                                AppButton(
                                  text: "Continue",
                                  color: AppColors.redTint35,
                                  textColor: Colors.white,
                                  disableBGColor: AppColors.redTint35
                                      .withValues(alpha: 0.35),
                                  disableTextColor: Colors.white70,
                                  enabled: !vm.isBaseBusy,
                                  isLoading: vm.isBaseBusy,
                                  press: () async {
                                    final ok = await ref2
                                        .read(deleteAccountViewModelProvider)
                                        .requestDeletionOtp();
                                    if (!dialogContext.mounted || !ok) {
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop();
                                    MobileNavigationService.instance.navigateTo(
                                      DeleteAccountOtpView.path,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SvgPicture.asset(
                SvgAssets.doubleTick,
                height: 10,
                width: 10,
              ),
            ),
            Gap.w16,
            Expanded(
              child: AppText.regular(
                text,
                fontSize: 12,
                height: 1.35,
                color: AppColors.mainBlack,
              ),
            ),
          ],
        ),
        Gap.h12,
        Container(height: 1, color: const Color(0xffFFEFE5)),
      ],
    );
  }
}
