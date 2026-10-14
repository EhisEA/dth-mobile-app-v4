import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<bool> showRemoveCartItemSheet(BuildContext context) async {
  final result = await showBlurredModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    borderRadius: BorderRadius.circular(48),
    margin: const EdgeInsets.all(16),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyTint30,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Gap.h24,
            AppText.medium(
              "Remove item from cart",
              fontSize: 20,
              color: AppColors.tertiary60,
              textAlign: TextAlign.center,
            ),
            Gap.h8,
            AppText.regular(
              "This action is permanent and cannot be undone. Are you sure you want to proceed?",
              fontSize: 14,
              height: 1.4,
              color: AppColors.tint25,
              textAlign: TextAlign.center,
              multiText: true,
            ),
            Gap.h32,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: "No, cancel",
                    onBorder: true,
                    color: AppColors.white,
                    textColor: AppColors.mainBlack,
                    borderColor: AppColors.mainBlack,
                    press: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(sheetContext).pop(false);
                    },
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: AppButton(
                    text: "Yes, remove",
                    color: AppColors.redTint35,
                    textColor: AppColors.white,
                    press: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(sheetContext).pop(true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
