import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/profile/bank_account/bank_account.dart";
import "package:dth_v4/features/profile/bank_account/view_model/bank_account_view_model.dart";
import "package:dth_v4/features/profile/bank_account/components/bank_account_card.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class BankAccountView extends ConsumerStatefulWidget {
  const BankAccountView({super.key});

  static const String path = NavigatorRoutes.bankAccount;

  @override
  ConsumerState<BankAccountView> createState() => _BankAccountViewState();
}

class _BankAccountViewState extends ConsumerState<BankAccountView> {
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
    final vm = ref.watch(bankAccountViewModelProvider);

    return Scaffold(
      appBar: DthAppBar(
        title: "Bank Accounts",
        actions: [
          GestureDetector(
            onTap: () {
              MobileNavigationService.instance.navigateTo(
                AddBankAccountView.path,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SvgPicture.asset(
                SvgAssets.addBankAccount,
                width: 32,
                height: 32,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: vm.hasBankAccounts
            ? Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...List.generate(vm.bankAccounts.length, (index) {
                            final bankAccount = vm.bankAccounts[index];
                            return BankAccountCard(
                              account: bankAccount,
                              onMoreClicked:  () async {
                                final result = await showMoreActionSheet(
                                  context,
                                  ref,
                                );

                                if (result == true && context.mounted) {
                                  showDeleteBankAccountConfirmationSheet(
                                    context,
                                    ref,
                                  );
                                }
                              }
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Column(
                  children: [
                    Gap.h(64),
                    Image.asset(ImageAssets.addBank, height: 159, width: 163),
                    Gap.h24,
                    AppText.medium(
                      "Add Your Bank Account",
                      fontSize: 16,
                      centered: true,
                      color: AppColors.tint30,
                    ),
                    Gap.h8,
                    AppText.regular(
                      "Save a bank account for easy access when you need to withdraw.",
                      fontSize: 14,
                      centered: true,
                      color: AppColors.paleLavender,
                    ),
                    Gap.h24,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 54),
                      child: AppButton.onBorder(
                        text: "Add Account",
                        isShort: true,
                        press: () {
                          MobileNavigationService.instance.navigateTo(
                            AddBankAccountView.path,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
