import "dart:ui";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/components/show_detail_hero.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Loading placeholder for [ShowView] — mirrors hero, sheet, about panel, and CTA.
class ShowViewSkeleton extends StatelessWidget {
  const ShowViewSkeleton({super.key});

  static const double _sheetOverlap = 25;
  static const double _sheetTopRadius = 24;
  static const double _contentPaddingH = 16;
  static const double _contentPaddingTop = 20;
  static const double _buyButtonHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShowDetailHeroSkeleton(),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -_sheetOverlap),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_sheetTopRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        _contentPaddingH,
                        _contentPaddingTop,
                        _contentPaddingH,
                        _contentPaddingTop,
                      ),
                      child: const _ShowContentSkeleton(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _contentPaddingH,
                      0,
                      _contentPaddingH,
                      0,
                    ),
                    child: _SkeletonBlock(
                      height: _buyButtonHeight,
                      radius: 100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero banner + nav control placeholders ([ShowDetailHero] layout).
class ShowDetailHeroSkeleton extends StatelessWidget {
  const ShowDetailHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: context.height * 0.45,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(color: AppColors.baseShimmer(context)),
          ),
          Positioned(
            top: topPad,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffF7F7F7),
                    ),
                    child: SvgPicture.asset(
                      SvgAssets.backArrow,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                const _NavButtonSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButtonSkeleton extends StatelessWidget {
  const _NavButtonSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMinInteractiveDimension,
      height: kMinInteractiveDimension,
      child: Center(
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: _SkeletonBlock(width: 40, height: 40, radius: 20),
          ),
        ),
      ),
    );
  }
}

class _ShowContentSkeleton extends StatelessWidget {
  const _ShowContentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBlock(width: 72, height: 22, radius: 8),
        Gap.h16,
        const _SkeletonLine(widthFactor: 1, height: 16),
        Gap.h6,
        // const _SkeletonLine(widthFactor: 0.65, height: 16),
        // Gap.h4,
        Row(
          children: [
            _SkeletonBlock(height: 12, width: 100, radius: 4),
            Gap.w8,

            const _SkeletonBlock(width: 80, height: 12, radius: 4),
          ],
        ),
        Gap.h16,
        const _AboutEventPanelSkeleton(),
      ],
    );
  }
}

/// Mirrors [ShowAboutEventPanel] (grey card, body lines, date/time/venue grid).
class _AboutEventPanelSkeleton extends StatelessWidget {
  const _AboutEventPanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyTint15,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBlock(width: 100, height: 14, radius: 4),
          Gap.h12,
          const _SkeletonLine(widthFactor: 1, height: 12),
          Gap.h8,
          const _SkeletonLine(widthFactor: 1, height: 12),
          Gap.h8,
          const _SkeletonLine(widthFactor: 0.92, height: 12),
          Gap.h8,
          const _SkeletonLine(widthFactor: 0.78, height: 12),
          Gap.h16,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _DetailCellSkeleton()),
              Gap.w8,
              Expanded(child: _DetailCellSkeleton()),
            ],
          ),
          Gap.h16,
          const _DetailCellSkeleton(),
        ],
      ),
    );
  }
}

class _DetailCellSkeleton extends StatelessWidget {
  const _DetailCellSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBlock(width: 36, height: 12, radius: 4),
        Gap.h4,
        const _SkeletonLine(widthFactor: 1, height: 12),
        Gap.h4,
        const _SkeletonLine(widthFactor: 0.7, height: 12),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: _SkeletonBlock(height: height, radius: 4),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.width, required this.height, this.radius = 6});

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
