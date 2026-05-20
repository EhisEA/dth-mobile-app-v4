import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class ConfirmationView extends StatelessWidget {
  const ConfirmationView({super.key, required this.isSuccess});
  static const String path = NavigatorRoutes.confirmation;

  final bool isSuccess;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: AppButton.onBorder(
            text: isSuccess ? "Dismiss" : "Try a different method",
            fontSize: 15,
            press: () {
              MobileNavigationService.instance.goBack();
            },
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
                  isSuccess
                      ? "Your payment was successful. You now have pro access to DTH 5."
                      : "We couldn't process your payment. Please try again or use a different method.",
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
}
