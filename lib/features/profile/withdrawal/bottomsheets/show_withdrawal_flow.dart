import "dart:async";
import "dart:ui" show ImageFilter;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/profile/bank_account/bank_account.dart";
import "package:dth_v4/features/profile/withdrawal/view_model/withdrawal_view_model.dart";
import "package:dth_v4/widgets/text/text.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:shimmer/shimmer.dart";

enum _WithdrawalStep { noBank, amount, selectBank, result }

/// Opens on the amount step; bank accounts load quietly in the background.
Future<void> showWithdrawalFlow(BuildContext context, WidgetRef ref) {
  ref.read(withdrawalViewModelProvider).reset();
  return _showBlurredSheet<void>(
    context,
    builder: (_) => const _WithdrawalFlowSheet(),
  );
}

Future<T?> _showBlurredSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
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
                          color: const Color(
                            0xff044423,
                          ).withValues(alpha: 0.12),
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
                    child: builder(dialogContext),
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

Widget _sheetCloseButton({required VoidCallback? onTap}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: AppColors.greyTint15,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.close_rounded, size: 12, color: AppColors.greyTint55),
    ),
  );
}

class _WithdrawalFlowSheet extends ConsumerStatefulWidget {
  const _WithdrawalFlowSheet();

  @override
  ConsumerState<_WithdrawalFlowSheet> createState() =>
      _WithdrawalFlowSheetState();
}

class _WithdrawalFlowSheetState extends ConsumerState<_WithdrawalFlowSheet> {
  _WithdrawalStep _step = _WithdrawalStep.amount;
  late final TextEditingController _amountController;
  late final FocusNode _amountFocus;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
      unawaited(_prefetchBanks());
    });
  }

  Future<void> _prefetchBanks() async {
    final vm = ref.read(withdrawalViewModelProvider);
    await vm.loadBankAccounts();
    if (!mounted) return;
    _resolveSelectBankAfterLoad(vm);
  }

  void _resolveSelectBankAfterLoad(WithdrawalViewModel vm) {
    if (_step != _WithdrawalStep.selectBank) return;
    if (vm.banksError != null) {
      setState(() {});
      return;
    }
    if (!vm.hasBankAccounts) {
      setState(() => _step = _WithdrawalStep.noBank);
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _syncAmountController() {
    final vm = ref.read(withdrawalViewModelProvider);
    final formatted = vm.formattedAmountDisplay;
    if (_amountController.text != formatted) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onAmountChanged(String value) {
    ref.read(withdrawalViewModelProvider).setAmountDigits(value);
    _syncAmountController();
  }

  void _onMax() {
    HapticFeedback.selectionClick();
    ref.read(withdrawalViewModelProvider).setMaxAmount();
    _syncAmountController();
  }

  void _goToSelectBank() {
    FocusScope.of(context).unfocus();
    final vm = ref.read(withdrawalViewModelProvider);
    if (!vm.canProceedAmount) return;
    if (vm.banksReady && !vm.hasBankAccounts) {
      setState(() => _step = _WithdrawalStep.noBank);
      return;
    }
    setState(() => _step = _WithdrawalStep.selectBank);
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    final withdrawal = await ref.read(withdrawalViewModelProvider).submit();
    if (!mounted || withdrawal == null) return;
    setState(() => _step = _WithdrawalStep.result);
  }

  Future<void> _retryLoadBanks() async {
    final vm = ref.read(withdrawalViewModelProvider);
    await vm.loadBankAccounts();
    if (!mounted) return;
    _resolveSelectBankAfterLoad(vm);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(withdrawalViewModelProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final body = switch (_step) {
      _WithdrawalStep.noBank => const _NoBankAccountBody(),
      _WithdrawalStep.amount => _AmountStep(
        controller: _amountController,
        focusNode: _amountFocus,
        hasInput: vm.amount > 0,
        availableLabel: vm.availableLabel,
        validationMessage: vm.amountValidationMessage,
        canProceed: vm.canProceedAmount,
        proceedLabel: vm.proceedCtaLabel,
        onChanged: _onAmountChanged,
        onMax: _onMax,
        onProceed: _goToSelectBank,
        onClose: () => Navigator.of(context).pop(),
      ),
      _WithdrawalStep.selectBank => _SelectBankStep(
        accounts: vm.bankAccounts,
        selectedUid: vm.selectedBankAccountUid,
        isBusy: vm.isBaseBusy,
        banksLoading: vm.banksLoading,
        banksError: vm.banksError,
        onRetry: _retryLoadBanks,
        onSelect: vm.selectBankAccount,
        onProceed: _submit,
        onAddBank: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
          MobileNavigationService.instance.navigateTo(AddBankAccountView.path);
        },
        onClose: vm.isBaseBusy ? null : () => Navigator.of(context).pop(),
      ),
      _WithdrawalStep.result => _ResultStep(
        withdrawal: vm.lastWithdrawal,
        onClose: () => Navigator.of(context).pop(),
      ),
    };

    return SafeArea(
      bottom: false,
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 32 + bottomInset),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: body,
        ),
      ),
    );
  }
}

class _BanksLoadingStep extends StatelessWidget {
  const _BanksLoadingStep({
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onClose,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppText.medium(
              "Withdraw funds",
              fontSize: 16,
              color: AppColors.tertiary60,
            ),
            const Spacer(),
            _sheetCloseButton(onTap: onClose),
          ],
        ),
        Gap.h8,
        AppText.regular(
          isLoading
              ? "Loading your bank accounts..."
              : (error ?? "Could not load bank accounts."),
          fontSize: 14,
          color: AppColors.tint25,
        ),
        Gap.h24,
        if (isLoading || error == null) ...[
          const _WithdrawalBanksSkeleton(),
          Gap.h16,
        ] else ...[
          AppText.regular(
            error!,
            fontSize: 13,
            color: AppColors.redTint35,
            multiText: true,
          ),
          Gap.h24,
          AppButton.primary(text: "Retry", press: onRetry),
        ],
      ],
    );
  }
}

class _WithdrawalBanksSkeleton extends StatelessWidget {
  const _WithdrawalBanksSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: Column(
        children: List.generate(2, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == 1 ? 0 : 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                Gap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Gap.h8,
                      Container(
                        height: 10,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NoBankAccountBody extends ConsumerWidget {
  const _NoBankAccountBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AppText.medium(
              "Set up bank account",
              fontSize: 16,
              color: AppColors.tertiary60,
            ),
            const Spacer(),
            _sheetCloseButton(onTap: () => Navigator.of(context).pop()),
          ],
        ),
        Gap.h8,
        Align(
          alignment: Alignment.centerLeft,
          child: AppText.regular(
            "Add your bank details to proceed",
            fontSize: 14,
            color: AppColors.tint25,
          ),
        ),
        Gap.h28,
        Image.asset(ImageAssets.addBank, height: 140),
        Gap.h16,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xffFDECEC),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, size: 16, color: AppColors.redTint35),
              Gap.w6,
              AppText.medium(
                "No bank account yet",
                fontSize: 12,
                color: AppColors.redTint35,
              ),
            ],
          ),
        ),
        Gap.h28,
        AppButton.primary(
          text: "Add bank details",
          press: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
            MobileNavigationService.instance.navigateTo(
              AddBankAccountView.path,
            );
          },
        ),
      ],
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.controller,
    required this.focusNode,
    required this.hasInput,
    required this.availableLabel,
    required this.validationMessage,
    required this.canProceed,
    required this.proceedLabel,
    required this.onChanged,
    required this.onMax,
    required this.onProceed,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasInput;
  final String availableLabel;
  final String? validationMessage;
  final bool canProceed;
  final String proceedLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onMax;
  final VoidCallback onProceed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final inputStyle = AppTextStyle.athleticsExtraBold.copyWith(
      fontSize: 44,
      height: 1.1,
      letterSpacing: -0.2,
      color: hasInput ? AppColors.mainBlack : AppColors.tint5,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Gap.w20,
            AppText.medium(
              "Withdraw funds",
              fontSize: 18,
              color: AppColors.tertiary60,
            ),

            _sheetCloseButton(onTap: onClose),
          ],
        ),
        Gap.h8,
        AppText.regular(
          "Enter amount to withdraw",
          fontSize: 14,
          color: AppColors.blackTint20,
          centered: true,
        ),
        Gap.h16,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AppText.semiBold(
                  "₦",
                  fontSize: 20,
                  letterSpacing: -0.2,
                  height: 1.1,
                  color: AppColors.mainBlack,
                ),
                Gap.w(2),
                IntrinsicWidth(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    style: inputStyle,
                    cursorColor: AppColors.primary,
                    keyboardAppearance: Brightness.light,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      hintText: "0",
                      hintStyle: inputStyle,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onMax,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: AppText.medium(
                  "Max",
                  fontSize: 12,
                  color: AppColors.tertiary60,
                ),
              ),
            ),
          ],
        ),
        Gap.h12,
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greyTint15,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.regular(
                  "Available: ",
                  fontSize: 12,
                  color: AppColors.tint25,
                  centered: true,
                ),
                AppText.semiBold(
                  availableLabel,
                  fontSize: 12,
                  color: AppColors.tint25,
                  centered: true,
                ),
              ],
            ),
          ),
        ),
        if (validationMessage != null) ...[
          Gap.h12,
          AppText.regular(
            validationMessage!,
            fontSize: 12,
            color: AppColors.redTint35,
            multiText: true,
            centered: true,
          ),
        ],
        Gap.h32,
        AppButton.primary(
          text: proceedLabel,
          enabled: canProceed,
          disableBGColor: AppColors.greyTint15,
          press: canProceed ? onProceed : null,
        ),
      ],
    );
  }
}

class _SelectBankStep extends StatelessWidget {
  const _SelectBankStep({
    required this.accounts,
    required this.selectedUid,
    required this.isBusy,
    required this.banksLoading,
    required this.banksError,
    required this.onRetry,
    required this.onSelect,
    required this.onProceed,
    required this.onAddBank,
    required this.onClose,
  });

  final List<BankAccount> accounts;
  final String? selectedUid;
  final bool isBusy;
  final bool banksLoading;
  final String? banksError;
  final VoidCallback onRetry;
  final ValueChanged<String> onSelect;
  final VoidCallback onProceed;
  final VoidCallback onAddBank;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (banksLoading || banksError != null) {
      return _BanksLoadingStep(
        isLoading: banksLoading,
        error: banksError,
        onRetry: onRetry,
        onClose: onClose ?? () {},
      );
    }

    final canProceed = (selectedUid?.trim().isNotEmpty ?? false) && !isBusy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Gap.w20,
            AppText.medium(
              "Withdraw funds",
              fontSize: 18,
              color: AppColors.tertiary60,
            ),
            _sheetCloseButton(onTap: onClose),
          ],
        ),
        Gap.h8,
        AppText.regular(
          "Select an account to receive your funds",
          fontSize: 14,
          color: AppColors.blackTint20,
          centered: true,
        ),
        Gap.h24,
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length + 1,
            separatorBuilder: (_, __) => Gap.w8,
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return _AddBankSelectCard(onTap: isBusy ? null : onAddBank);
              }
              final account = accounts[index];
              final selected = account.uid == selectedUid;
              return _BankSelectCard(
                account: account,
                selected: selected,
                onTap: isBusy
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onSelect(account.uid);
                      },
              );
            },
          ),
        ),
        Gap.h28,
        AppButton.primary(
          text: "Proceed",
          enabled: canProceed,
          isLoading: isBusy,
          press: canProceed ? onProceed : null,
        ),
      ],
    );
  }
}

class _AddBankSelectCard extends StatelessWidget {
  const _AddBankSelectCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyTint20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xffEEFCF5),
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            Gap.h14,
            AppText.medium(
              "Add another bank\naccount",
              fontSize: 12,
              height: 1.3,
              centered: true,
              color: AppColors.tertiary60,
            ),
          ],
        ),
      ),
    );
  }
}

class _BankSelectCard extends StatelessWidget {
  const _BankSelectCard({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final BankAccount account;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.greyTint20;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 201,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BankLogoAvatar(
                  bankName: account.bankName,
                  imageUrl: account.imageUrl,
                  size: 36,
                  fontSize: 12,
                ),
                Gap.h10,
                AppText.bold(
                  account.accountNumber,
                  fontSize: 16,
                  height: 1.3,
                  color: AppColors.black,
                ),
                AppText.medium(
                  account.accountName,
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.tint40,
                  maxLines: 1,
                ),
                AppText.regular(
                  account.bankName,
                  fontSize: 10,
                  color: AppColors.tint25,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Positioned(
            top: 13,
            right: 13,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xffE5FBF0),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffCCF7E1)),
              ),
              child: Container(
                padding: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({required this.withdrawal, required this.onClose});

  final Withdrawal? withdrawal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final successful = withdrawal?.isSuccessful ?? false;
    final amountLabel = withdrawal?.formattedAmountLabel ?? "₦0";

    final title = successful ? "Withdrawal Successful" : "Withdrawal Submitted";
    final messageLeading = successful ? "Your " : "Your ";
    final messageTrailing = successful
        ? " withdrawal has been sent to your bank account successfully."
        : " withdrawal is being processed. We'll notify you when it's complete.";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _sheetCloseButton(onTap: onClose),
        ),
        Gap.h8,
        Center(
          child: successful
              ? Image.asset(ImageAssets.confirmed, height: 88)
              : SvgPicture.asset(
                  SvgAssets.clock,
                  height: 56,
                  width: 56,
                  colorFilter: ColorFilter.mode(
                    AppColors.dthBlue,
                    BlendMode.srcIn,
                  ),
                ),
        ),
        Gap.h16,
        AppText.medium(
          title,
          fontSize: 18,
          height: 1.2,
          centered: true,
          color: AppColors.tertiary60,
        ),
        Gap.h8,
        Text.rich(
          TextSpan(
            style: AppTextStyle.regular.copyWith(
              fontSize: 16,
              height: 1.4,
              color: AppColors.tint25,
            ),
            children: [
              TextSpan(text: messageLeading),
              TextSpan(
                text: amountLabel,
                style: AppTextStyle.bold.copyWith(fontSize: 16),
              ),
              TextSpan(text: messageTrailing),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        Gap.h28,
        AppButton.onBorder(
          text: "Alright. Got it.",
          press: () {
            HapticFeedback.lightImpact();
            onClose();
          },
        ),
      ],
    );
  }
}
