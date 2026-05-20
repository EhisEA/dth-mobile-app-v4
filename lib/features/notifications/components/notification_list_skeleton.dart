import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:shimmer/shimmer.dart";

class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Block(width: 40, height: 40, radius: 20),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Block(height: 12, width: 200, radius: 4),
                    Gap.h6,
                    const _Block(height: 10, width: 80, radius: 4),
                    Gap.h10,
                    const _Block(height: 10, radius: 4),
                    Gap.h6,
                    const _Block(height: 10, widthFactor: 0.7, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    this.width,
    this.height = 12,
    this.radius = 4,
    this.widthFactor,
  });

  final double? width;
  final double height;
  final double radius;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (widthFactor != null) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: child,
      );
    }
    return child;
  }
}
