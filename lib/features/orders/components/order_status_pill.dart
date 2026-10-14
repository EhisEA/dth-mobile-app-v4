import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({super.key, required this.status, required this.label});

  final OrderStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      OrderStatus.delivered => (
        AppColors.primary,
        AppColors.white,
        SvgAssets.check,
      ),
      OrderStatus.cancelled => (
        AppColors.greyTint20,
        AppColors.blackTint20,
        SvgAssets.delete,
      ),
      OrderStatus.inProgress || OrderStatus.unknown => (
        const Color(0xffFFEFB5),
        AppColors.black,
        SvgAssets.phTimer,
      ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(child: SvgPicture.asset(icon, height: 8, width: 8)),
          ),
          Gap.w4,
          AppText.medium(
            label.isNotEmpty ? label : status.name,
            fontSize: 9,
            color: fg,
          ),
        ],
      ),
    );
  }
}
