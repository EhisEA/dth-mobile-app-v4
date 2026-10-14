import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:shimmer/shimmer.dart";

/// Full-page loading placeholder for [MyOrdersView].
class OrdersListSkeleton extends StatelessWidget {
  const OrdersListSkeleton({super.key, this.cardCount = 1});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: cardCount,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (index > 0) Gap.h20,
              const Center(child: _Block(width: 140, height: 12, radius: 4)),
              Gap.h12,
              const _OrderCardSkeleton(),
            ],
          );
        },
      ),
    );
  }
}

/// Compact shimmer used while loading the next page.
class OrdersLoadMoreSkeleton extends StatelessWidget {
  const OrdersLoadMoreSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: const Padding(
        padding: EdgeInsets.only(top: 12),
        child: _OrderCardSkeleton(),
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyTint30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Block(width: 20, height: 20, radius: 4),
              Gap.w8,
              const Expanded(child: _Block(height: 14, radius: 4)),
              Gap.w8,
              const _Block(width: 84, height: 24, radius: 100),
            ],
          ),
          Gap.h12,
          const _OrderItemSkeleton(),
          Gap.h8,
          const _OrderItemSkeleton(),
          Gap.h12,
          Row(
            children: [
              const _Block(width: 100, height: 14, radius: 4),
              const Spacer(),
              const _Block(width: 96, height: 32, radius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItemSkeleton extends StatelessWidget {
  const _OrderItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyTint30),
      ),
      child: Row(
        children: [
          const _Block(width: 44, height: 44, radius: 8),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Block(height: 12, radius: 4),
                Gap.h6,
                const _Block(width: 72, height: 10, radius: 4),
              ],
            ),
          ),
          Gap.w10,
          const _Block(width: 36, height: 24, radius: 8),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.width, this.height = 12, this.radius = 4});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.baseShimmer(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
