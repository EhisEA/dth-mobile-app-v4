import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:shimmer/shimmer.dart";

/// Single cart-line shimmer for [StoreCartView] loading.
class StoreCartSkeleton extends StatelessWidget {
  const StoreCartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: _CartLineSkeleton(),
      ),
    );
  }
}

class _CartLineSkeleton extends StatelessWidget {
  const _CartLineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Block(width: 20, height: 20, radius: 6),
              Gap.w12,
              const _Block(width: 56, height: 56, radius: 100),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Block(height: 14, radius: 4),
                    Gap.h8,
                    const _Block(width: 96, height: 12, radius: 4),
                    Gap.h8,
                    const _Block(width: 72, height: 14, radius: 4),
                  ],
                ),
              ),
              Gap.w12,
              const _Block(width: 36, height: 36, radius: 10),
            ],
          ),
          Gap.h16,
          Row(
            children: [
              const _Block(width: 36, height: 36, radius: 10),
              Gap.w10,
              const _Block(width: 28, height: 16, radius: 4),
              Gap.w10,
              const _Block(width: 36, height: 36, radius: 10),
            ],
          ),
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
