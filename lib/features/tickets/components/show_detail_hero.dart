import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ShowDetailHero extends StatelessWidget {
  const ShowDetailHero({
    super.key,
    required this.imageUrl,
    this.onBack,
    this.onShare,
  });

  final String imageUrl;
  final VoidCallback? onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: context.height * 0.45,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                ColoredBox(color: AppColors.baseShimmer(context)),
            errorWidget: (_, __, ___) => ColoredBox(
              color: AppColors.baseShimmer(context),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.tint15,
              ),
            ),
          ),
          Positioned(
            top: topPad,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShowDetailBackButton(onBack: onBack),
                CircleBlurIconButton(
                  onTap: onShare ?? () {},
                  child: SvgPicture.asset(SvgAssets.share),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Blurred circular back control for show detail hero, skeleton, and error.
class ShowDetailBackButton extends StatelessWidget {
  const ShowDetailBackButton({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return CircleBlurIconButton(
      onTap: onBack ?? () => Navigator.of(context).maybePop(),
      child: SvgPicture.asset(
        SvgAssets.backArrow,
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}

class CircleBlurIconButton extends StatelessWidget {
  const CircleBlurIconButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 40×40 visual, 48×48 minimum touch target (matches post detail back control).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: kMinInteractiveDimension,
          height: kMinInteractiveDimension,
          child: Center(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  color: const Color(0xffF7F7F7).withValues(alpha: 0.16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
