import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:shimmer/shimmer.dart";

/// Full-page loading placeholder for [StoreCatalogView] (merch + event).
class StoreCatalogSkeleton extends StatelessWidget {
  const StoreCatalogSkeleton({super.key, this.showPromoBanner = false});

  final bool showPromoBanner;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          if (showPromoBanner)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _Block(height: 120, radius: 16),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Block(height: 48, radius: 100),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                separatorBuilder: (_, __) => Gap.w8,
                itemBuilder: (_, __) =>
                    const _Block(width: 88, height: 34, radius: 40),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: const _ProductsGrid(itemCount: 2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Products-grid shimmer for when search/filters stay on screen.
class StoreCatalogProductsSkeleton extends StatelessWidget {
  const StoreCatalogProductsSkeleton({super.key, this.itemCount = 2});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: _ProductsGrid(itemCount: itemCount),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  const _ProductsGrid({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (_, __) => const _ProductCardSkeleton(),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: _Block(radius: 16)),
        Gap.h10,
        const _Block(height: 12, widthFactor: 0.85, radius: 4),
        Gap.h6,
        const _Block(height: 10, widthFactor: 0.55, radius: 4),
        Gap.h8,
        const _Block(height: 14, width: 64, radius: 4),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.width, this.height, this.radius = 8, this.widthFactor});

  final double? width;
  final double? height;
  final double radius;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.baseShimmer(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (widthFactor != null) {
      child = FractionallySizedBox(widthFactor: widthFactor, child: child);
    }
    return child;
  }
}
