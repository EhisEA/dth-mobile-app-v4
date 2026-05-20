import "dart:async";

import "package:dth_v4/data/models/subscription_model.dart";
import "package:dth_v4/features/subscription/components/subscription_plan_card.dart";
import "package:dth_v4/features/subscription/view_model/subscription_checkout_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SubscriptionWidget extends ConsumerStatefulWidget {
  const SubscriptionWidget({
    super.key,
    required this.plans,
    this.listScrollOffsetPx,
  });

  final List<SubscriptionModel> plans;
  final ValueNotifier<double>? listScrollOffsetPx;

  @override
  ConsumerState<SubscriptionWidget> createState() => _SubscriptionWidgetState();
}

class _SubscriptionWidgetState extends ConsumerState<SubscriptionWidget> {
  /// Sheet height as a fraction of the parent; scroll expands toward [maxChildSize].
  static const double _initialSheetFraction = 0.70;

  ScrollController? _scrollController;

  void _attachScrollReporting(ScrollController controller) {
    if (_scrollController == controller) return;
    _scrollController?.removeListener(_emitListScrollOffset);
    _scrollController = controller;
    _scrollController?.addListener(_emitListScrollOffset);
    // [scrollController] is not attached until the ListView from this builder mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitListScrollOffset();
    });
  }

  void _emitListScrollOffset() {
    final notifier = widget.listScrollOffsetPx;
    final c = _scrollController;
    if (notifier == null || c == null || !c.hasClients) return;
    final next = c.offset;
    if (notifier.value != next) notifier.value = next;
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_emitListScrollOffset);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutVm = ref.watch(subscriptionCheckoutViewModelProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scrollEndPadding = bottomInset + 70;

    SubscriptionModel? activePlan;
    for (final p in widget.plans) {
      if (p.isActiveSubscription) {
        activePlan = p;
        break;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: _initialSheetFraction,
      minChildSize: _initialSheetFraction,
      maxChildSize: 1.0,
      snap: true,
      builder: (context, scrollController) {
        _attachScrollReporting(scrollController);
        return ListView.separated(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, scrollEndPadding),
          itemCount: widget.plans.length,
          separatorBuilder: (_, __) => Gap.h16,
          itemBuilder: (context, index) {
            final plan = widget.plans[index];
            return Column(
              children: [
                SubscriptionPlanCard(
                  plan: plan,
                  activePlan: activePlan,
                  isCheckoutBusy: checkoutVm.isBaseBusy,
                  onCTATap: () {
                    if (activePlan != null && plan.uid == activePlan.uid) {
                      return;
                    }
                    if (activePlan != null &&
                        compareSubscriptionPlanTier(plan, activePlan) < 0) {
                      return;
                    }
                    unawaited(checkoutVm.purchasePlan(plan));
                    HapticFeedback.lightImpact();
                  },
                ),

                if (index == widget.plans.length - 1) Gap.h(100),
              ],
            );
          },
        );
      },
    );
  }
}
