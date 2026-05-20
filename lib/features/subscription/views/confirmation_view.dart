import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/views/show_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ConfirmationView extends StatelessWidget {
  const ConfirmationView({
    super.key,
    required this.isSuccess,
    required this.successDescription,
    required this.failureDescription,
    this.flow = ConfirmationFlow.subscription,
    this.eventUid,
    this.onSuccess,
  });

  static const String path = NavigatorRoutes.confirmation;

  final bool isSuccess;
  final String successDescription;
  final String failureDescription;
  final ConfirmationFlow flow;
  final String? eventUid;
  final Future<void> Function()? onSuccess;

  String get _description =>
      isSuccess ? successDescription : failureDescription;

  String get _dismissLabel => switch (flow) {
    ConfirmationFlow.ticket when isSuccess => "Back to event",
    ConfirmationFlow.subscription when isSuccess => "Dismiss",
    _ => "Try a different method",
  };

  @override
  Widget build(BuildContext context) {
    final dismissLabel = _dismissLabel;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: AppButton.onBorder(
            text: dismissLabel,
            fontSize: 15,
            press: () => unawaited(_onDismiss()),
          ),
        ),
      ),
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Gap.h16,
              Align(
                alignment: Alignment.centerRight,
                child: AppText.regular(
                  "Need Help?",
                  fontSize: 12,
                  color: AppColors.blackTint20,
                  textAlign: TextAlign.right,
                  height: 0,
                ),
              ),
              Center(
                child: SvgPicture.asset(
                  isSuccess ? SvgAssets.confirmed : SvgAssets.failed,
                ),
              ),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xffF1F3FE)
                        : const Color(0xffFFF2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: AppText.regular(
                      isSuccess ? "Successful" : "Unsuccessful",
                      fontSize: 11,
                      color: isSuccess
                          ? AppColors.secondaryBlue
                          : AppColors.redTint35,
                    ),
                  ),
                ),
              ),
              Gap.h8,
              Center(
                child: AppText.medium(
                  isSuccess ? "Payment Confirmed" : "Payment Failed",
                  fontSize: 18,
                  color: AppColors.mainBlack,
                  centered: true,
                ),
              ),
              Gap.h8,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppText.regular(
                  _description,
                  fontSize: 14,
                  color: AppColors.black,
                  centered: true,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDismiss() async {
    if (flow == ConfirmationFlow.ticket && isSuccess) {
      MobileNavigationService.instance.popUntil(ShowView.path);
      final callback = onSuccess;
      if (callback != null) {
        await callback();
      }
      return;
    }
    MobileNavigationService.instance.goBack();
  }
}
