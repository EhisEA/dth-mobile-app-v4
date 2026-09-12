import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/profile/bank_account/bank_account.dart";
import "package:dth_v4/features/profile/bank_account/components/bank_account_card.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(bankAccountViewModelProvider).loadAccounts());
    });
  }

  Future<void> _openAddBankAccount() async {
    await MobileNavigationService.instance.navigateTo(AddBankAccountView.path);
  }

  Widget _emptyState() {
    return Padding(
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
              press: _openAddBankAccount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountsList(List<BankAccount> accounts) {
    return Column(
      children: [
        Gap.h4,
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: accounts.length,
            separatorBuilder: (_, __) =>
                Container(height: 0.8, color: AppColors.greyTint25),
            itemBuilder: (context, index) {
              final bankAccount = accounts[index];
              return BankAccountCard(
                account: bankAccount,
                onMoreClicked: () async {
                  final result = await showMoreActionSheet(context);
                  if (result != true || !context.mounted) return;

                  final ok = await ref
                      .read(bankAccountViewModelProvider)
                      .requestBankAccountDeleteOtp(bankAccount.uid);
                  if (!ok || !context.mounted) return;

                  await showDeleteBankAccountConfirmationSheet(context, ref);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(bankAccountViewModelProvider);
    final bankAccountsState = ref.watch(bankAccountsStateProvider);

    return Loader.page(
      isLoading: vm.isBaseBusy,
      child: Scaffold(
        appBar: DthAppBar(
          title: "Bank Accounts",
          actions: [
            GestureDetector(
              onTap: _openAddBankAccount,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.greyTint15),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  SvgAssets.addBankAccount,
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: vm.listState.when(
            busy: () => const BankAccountListSkeleton(),
            error: (Failure failure) => Center(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 48,
                ),
                children: [
                  Gap.h24,
                  AppText.semiBold(
                    "Could not load bank accounts",
                    fontSize: 16,
                    color: AppColors.mainBlack,
                    textAlign: TextAlign.center,
                  ),
                  Gap.h12,
                  AppText.regular(
                    failure.message,
                    fontSize: 14,
                    color: AppColors.blackTint20,
                    textAlign: TextAlign.center,
                    multiText: true,
                  ),
                  Gap.h24,
                  Center(
                    child: AppButton.primary(
                      text: "Retry",
                      height: 48,
                      press: () => unawaited(vm.loadAccounts()),
                    ),
                  ),
                ],
              ),
            ),
            idle: () => ValueListenableBuilder<List<BankAccount>>(
              valueListenable: bankAccountsState.accounts,
              builder: (context, accounts, _) {
                if (accounts.isEmpty) return _emptyState();
                return _accountsList(accounts);
              },
            ),
          ),
        ),
      ),
    );
  }
}
