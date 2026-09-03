import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/features/voting/view_model/top_up_voting_credits_view_model.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:intl/intl.dart";

Future<void> showTopUpVotingCreditsSheet(BuildContext context) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    builder: (sheetContext) => const _TopUpVotingCreditsSheetBody(),
  );
}

class _TopUpVotingCreditsSheetBody extends ConsumerStatefulWidget {
  const _TopUpVotingCreditsSheetBody();

  @override
  ConsumerState<_TopUpVotingCreditsSheetBody> createState() =>
      _TopUpVotingCreditsSheetBodyState();
}

class _TopUpVotingCreditsSheetBodyState
    extends ConsumerState<_TopUpVotingCreditsSheetBody> {
  late final TextEditingController _inputController;
  late final FocusNode _inputFocus;
  static final _quantityFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _inputFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(topUpVotingCreditsViewModelProvider).reset();
      unawaited(ref.read(votingViewModelProvider).refreshWeek());
      _syncInputController();
      _inputFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _syncInputController() {
    final vm = ref.read(topUpVotingCreditsViewModelProvider);
    final formatted = switch (vm.inputMode) {
      TopUpInputMode.amount => vm.amount <= 0 ? "" : vm.formattedAmountDisplay,
      TopUpInputMode.credits =>
        vm.credits <= 0 ? "" : vm.formattedCreditsDisplay,
    };
    if (_inputController.text != formatted) {
      _inputController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onInputChanged(String value) {
    final vm = ref.read(topUpVotingCreditsViewModelProvider);
    if (vm.inputMode == TopUpInputMode.amount) {
      _onAmountChanged(value);
    } else {
      _onCreditsChanged(value);
    }
  }

  void _onAmountChanged(String value) {
    final digits = value.replaceAll(RegExp(r"[^0-9]"), "");
    final vm = ref.read(topUpVotingCreditsViewModelProvider);
    vm.setAmountDigits(digits);
    final formatted = vm.amount <= 0 ? "" : vm.formattedAmountDisplay;
    if (_inputController.text != formatted) {
      _inputController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onCreditsChanged(String value) {
    final digits = value.replaceAll(RegExp(r"[^0-9]"), "");
    final vm = ref.read(topUpVotingCreditsViewModelProvider);
    vm.setCreditsDigits(digits);
    final formatted = vm.credits <= 0 ? "" : vm.formattedCreditsDisplay;
    if (_inputController.text != formatted) {
      _inputController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onModeChanged(TopUpInputMode mode) {
    final vm = ref.read(topUpVotingCreditsViewModelProvider);
    if (vm.inputMode == mode) return;
    vm.setInputMode(mode);
    _syncInputController();
    _inputFocus.requestFocus();
  }

  Future<void> _onProceed() async {
    final vm = ref.read(topUpVotingCreditsViewModelProvider);
    if (!vm.canProceed) return;
    FocusScope.of(context).unfocus();
    await vm.purchase(
      onCheckoutReady: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(topUpVotingCreditsViewModelProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasInput = vm.hasInput;
    final quote = vm.quote;
    final canProceed = vm.canProceed;
    final isAmountMode = vm.inputMode == TopUpInputMode.amount;
    final inputStyle = AppTextStyle.athleticsExtraBold.copyWith(
      fontSize: 44,
      height: 1.1,
      letterSpacing: -0.2,
      color: hasInput ? AppColors.mainBlack : AppColors.tint5,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText.medium(
                      "Top up voting credit",
                      fontSize: 18,
                      color: AppColors.tertiary60,
                      textAlign: TextAlign.center,
                    ),
                    Gap.h4,
                    AppText.regular(
                      isAmountMode
                          ? "How much do you want to top up?"
                          : "How many voting credits do you want?",
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.blackTint20,
                      textAlign: TextAlign.center,
                      multiText: true,
                      letterSpacing: -0.2,
                    ),
                    Gap.h20,
                    Align(
                      alignment: Alignment.center,
                      child: _TopUpModeToggle(
                        selected: vm.inputMode,
                        onChanged: _onModeChanged,
                      ),
                    ),
                    Gap.h24,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isAmountMode) ...[
                          AppText.semiBold(
                            vm.currencySymbol,
                            fontSize: 20,
                            letterSpacing: -0.2,
                            height: 1.1,
                            color: AppColors.mainBlack,
                          ),
                        ],
                        IntrinsicWidth(
                          child: TextField(
                            controller: _inputController,
                            focusNode: _inputFocus,
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
                            onChanged: _onInputChanged,
                          ),
                        ),
                      ],
                    ),
                    if (quote != null &&
                        hasInput &&
                        vm.amountValidationMessage == null) ...[
                      Gap.h12,
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: AppTextStyle.regular.copyWith(
                              fontSize: 14,
                              color: AppColors.blackTint20,
                            ),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: SvgPicture.asset(
                                    SvgAssets.confetti,
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                              ),
                              if (isAmountMode) ...[
                                const TextSpan(text: "You'll receive "),
                                TextSpan(
                                  text: _quantityFormat.format(quote.quantity),
                                  style: AppTextStyle.bangersRegular.copyWith(
                                    fontSize: 14,
                                    letterSpacing: 0,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: " voting credits",
                                  style: AppTextStyle.semiBold.copyWith(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ] else ...[
                                const TextSpan(text: "You'll pay "),
                                TextSpan(
                                  text:
                                      "${quote.currencySymbol}${quote.amount.toMoneyWholeNumber()}",
                                  style: AppTextStyle.bangersRegular.copyWith(
                                    fontSize: 14,
                                    letterSpacing: 0,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else if (vm.quoteState.isBusy && hasInput) ...[
                      Gap.h12,
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoActivityIndicator(
                              radius: 7,
                              color: AppColors.primary,
                            ),
                            Gap.w8,
                            AppText.regular(
                              isAmountMode
                                  ? "Calculating voting credits"
                                  : "Calculating amount",
                              fontSize: 14,
                              color: const Color(0xff666666),
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ],
                        ),
                      ),
                    ] else if (vm.amountValidationMessage != null) ...[
                      Gap.h12,
                      Center(
                        child: AppText.regular(
                          vm.amountValidationMessage!,
                          fontSize: 14,
                          color: AppColors.redTint35,
                          textAlign: TextAlign.center,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                    Gap.h32,
                    AppButton.primary(
                      text: vm.proceedLabel,
                      enabled: canProceed,
                      isLoading: vm.isPurchaseBusy,
                      height: 55,
                      disableBGColor: AppColors.greyTint25,
                      disableTextColor: AppColors.tint10,
                      fontSize: 16,
                      press: canProceed ? () => unawaited(_onProceed()) : null,
                    ),
                    Gap.h16,
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.greyTint15,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.greyTint55,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

class _TopUpModeToggle extends StatelessWidget {
  const _TopUpModeToggle({required this.selected, required this.onChanged});

  final TopUpInputMode selected;
  final ValueChanged<TopUpInputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.greyTint20,
        border: Border.all(color: AppColors.greyTint30),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: "Amount",
            isActive: selected == TopUpInputMode.amount,
            onTap: () => _select(TopUpInputMode.amount),
          ),
          Gap.w4,
          _Segment(
            label: "Credits",
            isActive: selected == TopUpInputMode.credits,
            onTap: () => _select(TopUpInputMode.credits),
          ),
        ],
      ),
    );
  }

  void _select(TopUpInputMode next) {
    if (selected == next) return;
    HapticFeedback.selectionClick();
    onChanged(next);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AppText.regular(
            label,
            fontSize: 14,
            color: isActive ? AppColors.mainBlack : const Color(0xff666666),
            maxLines: 1,
            height: 1.2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
