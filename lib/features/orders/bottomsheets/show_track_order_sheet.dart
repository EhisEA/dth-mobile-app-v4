import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showTrackOrderSheet(BuildContext context, {required Order order}) {
  final steps = _buildTrackingSteps(order);

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
                  step: steps[i].step,
                  isLast: i == steps.length - 1,
                  completed: steps[i].completed,
                  showConnectorCompleted:
                      steps[i].completed &&
                      i + 1 < steps.length &&
                      steps[i + 1].completed,
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

class _DisplayTrackingStep {
  const _DisplayTrackingStep({required this.step, required this.completed});

  final OrderTimelineStep step;
  final bool completed;
}

/// Expected fulfillment path. Past API events stay completed; the rest are greyed.
const _kPipeline = <OrderTimelineStep>[
  OrderTimelineStep(
    status: "placed",
    title: "Order placed",
    description: "Your order was placed successfully",
  ),
  OrderTimelineStep(
    status: "processing",
    title: "Processing",
    description: "We're preparing your order",
  ),
  OrderTimelineStep(
    status: "shipped",
    title: "Out for delivery",
    description: "Your order is on its way",
  ),
  OrderTimelineStep(
    status: "delivered",
    title: "Delivered",
    description: "Your order has been delivered",
  ),
];

const _kCancelledStep = OrderTimelineStep(
  status: "cancelled",
  title: "Cancelled",
  description: "This order was cancelled",
);

List<_DisplayTrackingStep> _buildTrackingSteps(Order order) {
  final past = order.timeline;
  if (order.isCancelled) {
    final completed = [
      for (final step in past)
        _DisplayTrackingStep(step: step, completed: true),
    ];
    final hasCancel = past.any(
      (s) => _pipelineKeyFromText(s.status, s.title) == "cancelled",
    );
    if (!hasCancel) {
      completed.add(
        const _DisplayTrackingStep(step: _kCancelledStep, completed: true),
      );
    }
    return completed;
  }

  // Each past event maps to at most one pipeline slot (title first, then status).
  final matched = List<OrderTimelineStep?>.filled(_kPipeline.length, null);
  for (final step in past) {
    final index = _pipelineIndexFor(step);
    if (index == null) continue;
    matched[index] ??= step;
  }

  var reached = -1;
  for (var i = 0; i < matched.length; i++) {
    if (matched[i] != null) reached = i;
  }
  if (order.isDelivered) {
    reached = _kPipeline.length - 1;
  }

  return [
    for (var i = 0; i < _kPipeline.length; i++)
      _DisplayTrackingStep(
        step: matched[i] ?? _kPipeline[i],
        completed: i <= reached,
      ),
  ];
}

/// Prefer title so status values like `in_progress` don't also fill Processing.
int? _pipelineIndexFor(OrderTimelineStep step) {
  final title = step.title.trim().toLowerCase();
  for (var i = 0; i < _kPipeline.length; i++) {
    if (_kPipeline[i].title.toLowerCase() == title) return i;
  }

  final fromTitle = _pipelineKeyFromText("", title);
  final fromStatus = _pipelineKeyFromText(step.status, "");
  final key = fromTitle ?? fromStatus;
  if (key == null) return null;

  for (var i = 0; i < _kPipeline.length; i++) {
    if (_kPipeline[i].status == key) return i;
  }
  return null;
}

String? _pipelineKeyFromText(String status, String title) {
  final s = "$status $title".trim().toLowerCase().replaceAll(" ", "_");
  if (s.isEmpty) return null;
  if (s.contains("cancel")) return "cancelled";
  if (s.contains("deliver") || s.contains("completed")) return "delivered";
  if (s.contains("ship") || s.contains("transit") || s.contains("out_for")) {
    return "shipped";
  }
  // Title "Order placed" must win over status `in_progress` / `progress`.
  if (s.contains("place") || s.contains("paid") || s.contains("confirm")) {
    return "placed";
  }
  if (s.contains("process") || s.contains("prepar")) return "processing";
  if (title.trim().isEmpty && s.contains("progress")) return "processing";
  return null;
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
