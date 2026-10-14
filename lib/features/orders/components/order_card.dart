import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/orders/bottomsheets/show_track_order_sheet.dart";
import "package:dth_v4/features/orders/components/order_delivering_to_row.dart";
import "package:dth_v4/features/orders/components/order_item_row.dart";
import "package:dth_v4/features/orders/components/order_pickup_code_row.dart";
import "package:dth_v4/features/orders/components/order_status_pill.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class OrderCard extends ConsumerStatefulWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> {
  static const _previewCount = 2;
  bool _expanded = false;
  bool _tracking = false;
  bool _reordering = false;

  Order get order => widget.order;
  bool get _actionBusy => _tracking || _reordering;

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    final hiddenCount = items.length - _previewCount;
    final visibleItems = _expanded || hiddenCount <= 0
        ? items
        : items.take(_previewCount).toList(growable: false);
    final symbol = order.currencySymbol;
    final isMerch = order.storeType.toLowerCase() == "merch";
    final deliveringTo = order.deliveringTo?.trim();
    final showDeliveringTo =
        isMerch && deliveringTo != null && deliveringTo.isNotEmpty;
    final pickupCode = order.pickupCode?.trim();
    final showPickupCode = pickupCode != null && pickupCode.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyTint30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(SvgAssets.proiconsBox, width: 20, height: 20),
              Gap.w8,
              Expanded(
                child: AppText.medium(
                  order.title,
                  fontSize: 16,
                  color: AppColors.mainBlack,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap.w8,
              OrderStatusPill(status: order.status, label: order.statusLabel),
            ],
          ),
          Gap.h16,
          ...visibleItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OrderItemRow(
                item: item,
                currencySymbol: symbol,
                isMerch: isMerch,
              ),
            ),
          ),
          if (!_expanded && hiddenCount > 0) ...[
            Gap.h4,
            Row(
              children: [
                AppText.regular(
                  "$hiddenCount More",
                  fontSize: 12,
                  color: AppColors.blackTint20,
                ),
                Gap.w10,
                Expanded(
                  child: Container(height: 1, color: AppColors.greyTint25),
                ),
                Gap.w10,
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _expanded = true);
                  },
                  child: AppText.medium(
                    "See all",
                    fontSize: 12,
                    color: AppColors.mainBlack,
                  ),
                ),
              ],
            ),
            Gap.h8,
          ],
          Gap.h4,
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7.5,
                  ),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(ImageAssets.ordersGroup1),
                    ),
                  ),
                  child: Row(
                    children: [
                      AppText.medium(
                        "Total:  ",
                        fontSize: 14,
                        color: AppColors.tint25,
                      ),
                      AppText.bold(
                        "$symbol${order.total.value.toMoneyWholeNumber()}",
                        fontSize: 16,
                        color: AppColors.mainBlack,
                      ),
                    ],
                  ),
                ),
              ),
              Gap.w8,
              if (order.canTrack || order.canReorder)
                GestureDetector(
                  onTap: () {
                    if (_actionBusy) return;
                    HapticFeedback.lightImpact();
                    if (order.canTrack) {
                      unawaited(_trackOrder());
                    } else {
                      unawaited(_reorder());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    constraints: const BoxConstraints(minWidth: 108),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xff49597B)),
                    ),
                    child: _actionBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.mainBlack,
                            ),
                          )
                        : AppText.medium(
                            order.canTrack ? "Track order" : "Order again",
                            fontSize: 12,
                            color: AppColors.mainBlack,
                          ),
                  ),
                ),
            ],
          ),
          if (showDeliveringTo || showPickupCode) ...[
            Gap.h16,
            if (showDeliveringTo) OrderDeliveringToRow(address: deliveringTo),
            if (showDeliveringTo && showPickupCode) ...[
              Gap.h16,
              Container(height: 1, color: AppColors.greyTint25),
              Gap.h16,
            ],
            if (showPickupCode) OrderPickupCodeRow(code: pickupCode),
          ],
        ],
      ),
    );
  }

  Future<void> _trackOrder() async {
    if (_tracking) return;
    setState(() => _tracking = true);
    try {
      final detail = await ref
          .read(ordersRepositoryProvider)
          .getOrder(order.uid);
      if (!mounted) return;
      await showTrackOrderSheet(context, order: detail);
    } on ApiFailure catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(title: "Track order", message: e.message);
    } catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(
        title: "Track order",
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _tracking = false);
    }
  }

  Future<void> _reorder() async {
    if (_reordering) return;
    setState(() => _reordering = true);
    try {
      final result = await ref
          .read(ordersRepositoryProvider)
          .reorder(order.uid);
      final cart = ref.read(storeCartStateProvider);
      try {
        await cart.fetchCart(quiet: true);
      } catch (_) {
        // Still open cart; badge may refresh on next fetch.
      }
      if (!mounted) return;

      if (result.skipped.isNotEmpty) {
        final reasons = result.skipped
            .map((s) => s.reason.isNotEmpty ? s.reason : s.name)
            .where((s) => s.isNotEmpty)
            .join("\n");
        DthFlushBar.instance.showError(
          title: "Some items skipped",
          message: reasons.isNotEmpty
              ? reasons
              : "Some items could not be added.",
        );
      }

      MobileNavigationService.instance.navigateTo(
        StoreCartView.path,
        extra: {RoutingArgumentKey.storeCartKind: result.kind.name},
      );
    } on ApiFailure catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(title: "Order again", message: e.message);
    } catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(
        title: "Order again",
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }
}
