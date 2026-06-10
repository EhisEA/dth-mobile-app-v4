import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:shimmer/shimmer.dart";

/// Animated shimmer fill used as an image placeholder while network media
/// loads (post images, banners). Expands to fill its parent's constraints, so
/// it drops straight into a [CachedNetworkImage] `placeholder` that already
/// sits inside a sized box.
///
/// Defaults to the app's light shimmer palette; pass [baseColor]/
/// [highlightColor] for dark surfaces such as the livestream banner.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.baseColor, this.highlightColor});

  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final base = baseColor ?? AppColors.baseShimmer(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlightColor ?? AppColors.hightlightShimmer(context),
      child: ColoredBox(color: base),
    );
  }
}
