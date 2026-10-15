import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";

import "package:dth_v4/widgets/widgets.dart";
import "package:dth_v4/features/store/store.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreProductCard extends StatelessWidget {
  const StoreProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final StoreProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercent;
    final sizesLabel = product.sizes.isEmpty
        ? product.storeName
        : product.sizes.map(storeSizeDisplayLabel).join(", ");

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: const Color(0xffF2F2F2),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          ColoredBox(color: AppColors.greyTint20),
                      errorWidget: (_, __, ___) =>
                          ColoredBox(color: AppColors.greyTint20),
                    ),
                  ),
                ),
                if (discount != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFE9E8),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: AppText.semiBold(
                        "-$discount%",
                        fontSize: 8,
                        color: AppColors.redTint35,
                      ),
                    ),
                  ),
                if (product.soldOut)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.redTint35,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: AppText.semiBold(
                        "Sold-Out",
                        fontSize: 11,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Gap.h8,
          AppText.semiBold(
            product.title,
            fontSize: 16,
            color: AppColors.mainBlack,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h(2),
          AppText.medium(
            sizesLabel,
            fontSize: 12,
            color: AppColors.blackTint20,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h8,
          Container(height: 1, color: const Color(0xffF1F3F9)),
          Gap.h8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.bold(
                "${product.currencySymbol}${product.price.toMoneyWholeNumber()}",
                fontSize: 16,
                height: 1,
                letterSpacing: -0.1,
                color: AppColors.primary,
              ),
              if (product.originalPrice != null) ...[
                Gap.w4,
                AppText.medium(
                  "${product.currencySymbol}${product.originalPrice!.toMoneyWholeNumber()}",
                  fontSize: 13,
                  height: 1,
                  color: const Color(0xff7482A9),
                  decoration: TextDecoration.lineThrough,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
