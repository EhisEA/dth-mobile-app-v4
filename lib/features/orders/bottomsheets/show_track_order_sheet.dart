import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showTrackOrderSheet(BuildContext context, {required Order order}) {
  final steps = order.timeline;

  return showBlurredModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: false,
    borderRadius: BorderRadius.circular(48),
    margin: const EdgeInsets.all(16),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
            Gap.h20,
            if (steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AppText.regular(
                  "Tracking details are not available yet.",
                  fontSize: 14,
                  color: AppColors.blackTint20,
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (var i = 0; i < steps.length; i++) ...[
                _TrackingStepRow(
                  step: steps[i],
                  isLast: i == steps.length - 1,
                  completed: steps[i].reached,
                  showConnectorCompleted:
                      steps[i].reached &&
                      i + 1 < steps.length &&
                      steps[i + 1].reached,
                ),
              ],
            Gap.h20,
            AppButton.onBorder(
              text: "Alright. Got it.",
              fontSize: 15,
              borderColor: AppColors.mainBlack,
              textColor: AppColors.mainBlack,
              press: () {
                HapticFeedback.selectionClick();
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

class _TrackingStepRow extends StatelessWidget {
  const _TrackingStepRow({
    required this.step,
    required this.isLast,
    required this.completed,
    required this.showConnectorCompleted,
  });

  final OrderTimelineStep step;
  final bool isLast;
  final bool completed;
  final bool showConnectorCompleted;

  @override
  Widget build(BuildContext context) {
    final titleColor = completed ? AppColors.mainBlack : AppColors.greyTint50;
    final bodyColor = completed ? AppColors.blackTint20 : AppColors.greyTint50;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? AppColors.primary : AppColors.greyTint25,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      completed ? SvgAssets.doubleTick : SvgAssets.phTimer,
                      height: 10,
                      width: 10,
                      colorFilter: ColorFilter.mode(
                        completed ? AppColors.white : AppColors.blackTint20,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: showConnectorCompleted
                          ? AppColors.primary
                          : AppColors.greyTint30,
                    ),
                  ),
              ],
            ),
          ),
          Gap.w12,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText.semiBold(
                          step.title,
                          fontSize: 14,
                          color: titleColor,
                        ),
                      ),
                      if (completed && step.timeAgo != null)
                        AppText.medium(
                          step.timeAgo!,
                          fontSize: 10,
                          color: AppColors.dthBlue,
                        ),
                    ],
                  ),
                  if (step.description.isNotEmpty) ...[
                    Gap.h4,
                    AppText.medium(
                      step.description,
                      fontSize: 12,
                      color: bodyColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
