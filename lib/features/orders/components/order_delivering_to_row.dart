import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class OrderDeliveringToRow extends StatelessWidget {
  const OrderDeliveringToRow({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            ImageAssets.ordersDeliveringToMap,
            width: 67,
            height: 52,
            fit: BoxFit.cover,
          ),
        ),
        Gap.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bold(
                "DELIVERING TO:",
                fontSize: 8,
                color: const Color(0xff4E5A7E),
                letterSpacing: 1.6,
              ),
              Gap.h4,
              AppText.medium(
                address,
                fontSize: 14,
                color: AppColors.black,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
