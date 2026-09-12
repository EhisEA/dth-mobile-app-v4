import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:shimmer/shimmer.dart";

class BankAccountListSkeleton extends StatelessWidget {
  const BankAccountListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) =>
            Container(height: 0.8, color: Colors.white),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap.w8,
              const _Block(width: 40, height: 40, radius: 20),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Block(height: 14, width: 120, radius: 4),
                    Gap.h8,
                    const _Block(height: 12, width: 90, radius: 4),
                    Gap.h6,
                    const _Block(height: 10, width: 140, radius: 4),
                  ],
                ),
              ),
              const _Block(width: 28, height: 28, radius: 14),
            ],
          ),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
