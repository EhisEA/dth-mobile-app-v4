import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.isMerch,
  });

  final OrderItem item;
  final String currencySymbol;
  final bool isMerch;

  // String? get _subtitle {
  //   if (isMerch) {
  //     final parts = [
  //       if (item.size != null && item.size!.isNotEmpty) item.size!,
  //       if (item.color != null && item.color!.isNotEmpty) item.color!,
  //     ];
  //     if (parts.isEmpty) return null;
  //     return parts.join(" · ");
  //   }
  //   return item.vendor;
  // }

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    // final subtitle = _subtitle;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyTint30),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 41,
              height: 36,
              child: imageUrl == null
                  ? ColoredBox(color: AppColors.greyTint20)
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          ColoredBox(color: AppColors.greyTint20),
                      errorWidget: (_, __, ___) =>
                          ColoredBox(color: AppColors.greyTint20),
                    ),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.medium(
                  item.name,
                  fontSize: 14,
                  color: AppColors.mainBlack,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // if (subtitle != null) ...[
                //   Gap.h2,
                //   AppText.regular(
                //     subtitle,
                //     fontSize: 11,
                //     color: AppColors.blackTint20,
                //     maxLines: 1,
                //     overflow: TextOverflow.ellipsis,
                //   ),
                // ],
                Gap.h2,
                AppText.semiBold(
                  "$currencySymbol${item.unitPrice.toMoneyWholeNumber()}",
                  fontSize: 12,
                  color: const Color(0xff4E5A7E),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.greyTint30),
            ),
            child: AppText.semiBold(
              "x${item.quantity}",
              fontSize: 12,
              color: AppColors.mainBlack,
            ),
          ),
        ],
      ),
    );
  }
}
