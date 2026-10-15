import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/data/models/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCartLineTile extends StatelessWidget {
  const StoreCartLineTile({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.onToggleSelected,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final StoreCartItem item;
  final String currencySymbol;
  final VoidCallback onToggleSelected;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final sizeLabel = storeSizeFullLabel(item.variant.size);
    final colorName = item.variant.color?.name;
    final meta = [
      if (sizeLabel.isNotEmpty) "Size: $sizeLabel",
      if (colorName != null && colorName.isNotEmpty) colorName,
    ].join(" · ");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggleSelected();
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: item.isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: item.isSelected
                          ? AppColors.primary
                          : const Color(0xffD2D2D2),
                      width: 1.5,
                    ),
                  ),
                  child: item.isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : const Icon(
                          Icons.check,
                          size: 14,
                          color: Color(0xffD2D2D2),
                        ),
                ),
              ),
              Gap.w12,
              ClipRRect(
                borderRadius: BorderRadius.circular(10000),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.greyTint20,
                    shape: BoxShape.circle,
                  ),
                  width: 36,
                  height: 36,
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
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.medium(
                      product.name,
                      fontSize: 16,
                      color: AppColors.mainBlack,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta.isNotEmpty) ...[
                      Gap.h4,
                      AppText.regular(
                        meta,
                        fontSize: 12,
                        color: AppColors.blackTint20,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    Gap.h6,
                    AppText.semiBold(
                      "$currencySymbol${item.unitPrice.toMoneyWholeNumber()}",
                      fontSize: 14,
                      height: 1,
                      letterSpacing: -0.1,
                      color: AppColors.blackTint20,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (item.quantity <= 1) {
                        onRemove();
                      } else {
                        onDecrement();
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.quantity <= 1
                            ? AppColors.redTint35
                            : AppColors.tint40,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.quantity <= 1
                            ? Icons.delete_outline
                            : Icons.remove,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Gap.w4,
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.greyTint35, width: 1),
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    width: 36,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.85,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: AppText.medium(
                        "${item.quantity}",
                        key: ValueKey(item.quantity),
                        fontSize: 14,
                        color: AppColors.black,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Gap.w4,
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onIncrement();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, size: 16, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.hasProblem) ...[
            Gap.h8,
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: AppText.medium(
                item.problem!,
                fontSize: 12,
                color: AppColors.redTint35,
                multiText: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
