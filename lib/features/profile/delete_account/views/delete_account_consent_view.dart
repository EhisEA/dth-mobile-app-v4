import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/profile/delete_account/view_model/delete_account_view_model.dart";
import "package:dth_v4/features/profile/delete_account/bottomsheets/show_delete_account_confirmation_sheet.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class DeleteAccountConsentView extends ConsumerStatefulWidget {
  const DeleteAccountConsentView({super.key});

  static const String path = NavigatorRoutes.deleteAccountConsent;

  @override
  ConsumerState<DeleteAccountConsentView> createState() =>
      _DeleteAccountConsentViewState();
}

class _DeleteAccountConsentViewState
    extends ConsumerState<DeleteAccountConsentView> {
  late final TapGestureRecognizer _supportPrivacyTap;

  @override
  void initState() {
    super.initState();
    _supportPrivacyTap = TapGestureRecognizer()..onTap = _onSupportPrivacyTap;
  }

  @override
  void dispose() {
    _supportPrivacyTap.dispose();
    super.dispose();
  }

  void _onSupportPrivacyTap() {
    HapticFeedback.lightImpact();
    MobileNavigationService.instance.navigateTo(
      AppWebView.path,
      extra: {
        RoutingArgumentKey.title: "Privacy Policy",
        RoutingArgumentKey.initialURl: AppLink.privacyPolicy,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(deleteAccountViewModelProvider);

    return Scaffold(
      appBar: const DthAppBar(title: "Delete Account"),
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Gap.h16,
                    AppText.regular(
                      "Deleting your account is permanent. We handle your data "
                      "in line with applicable financial services and data protection regulations.",
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h24,
                    AppText.semiBold(
                      "What you should know:",
                      fontSize: 12,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h12,
                    AppText.semiBold(
                      "1. Deactivation period",
                      fontSize: 12,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h6,
                    AppText.regular(
                      "When you request deletion, your account will be deactivated for 30 days.\n\n"
                      " •  Do not log in during this period.\n"
                      " •  If you log in, the deletion request will be canceled.\n\n"
                      "After 30 days, your account and all related data will be permanently deleted.",
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h24,
                    AppText.semiBold(
                      "2. Data deletion and retention",
                      fontSize: 12,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h6,
                    AppText.regular(
                      " •  Your personal data will be deleted or anonymized, making it no longer identifiable.\n"
                      " •  Some information (like transaction records) will be retained for a legally required period (typically 5–7 years) to comply with data privacy and financial regulations.",
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h24,
                    AppText.semiBold(
                      "3. Why some data may be kept",
                      fontSize: 12,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h6,
                    AppText.regular(
                      "Data that must be retained will be stripped of personal identifiers and stored solely for:",
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h6,
                    AppText.regular(
                      " •  Audit purposes\n"
                      " •  Fraud prevention\n"
                      " •  Regulatory reporting",
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h24,
                    AppText.semiBold(
                      "Need help?",
                      fontSize: 12,
                      color: AppColors.mainBlack,
                    ),
                    Gap.h8,
                    Text.rich(
                      TextSpan(
                        style: AppTextStyle.regular.copyWith(
                          fontSize: 13,
                          color: AppColors.mainBlack,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                "If you have questions or would like assistance, please feel free to contact our support team at ",
                          ),
                          TextSpan(
                            text: "support@dth.ng",
                            style: AppTextStyle.medium.copyWith(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                            recognizer: _supportPrivacyTap,
                          ),
                        ],
                      ),
                    ),
                    Gap.h24,
                    AppText.semiBold(
                      "Give consent",
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                    Gap.h8,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            side: BorderSide(color: const Color(0xffC7C7C7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            value: vm.consentGiven,
                            onChanged: (_) => vm.toggleConsent(),
                            activeColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Gap.w12,
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: vm.toggleConsent,
                            child: AppText.regular(
                              "By proceeding, you confirm that you understand and "
                              "accept the conditions outlined above.",
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap.h24,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AppButton.primary(
                fontSize: 14,
                disableTextColor: AppColors.tint10,
                disableBGColor: AppColors.greyTint25,
                text: "Request account deletion",
                enabled: vm.consentGiven,
                press: () {
                  showDeleteAccountConfirmationSheet(context, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
