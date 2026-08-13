import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/components/ticket_event_card.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Loading placeholders for [TicketView] — matches booked/upcoming row layout.
class TicketHomeSkeleton extends StatelessWidget {
  const TicketHomeSkeleton({
    super.key,
    this.showUpcomingSection = true,
    this.bookedPlaceholderCount = 4,
  });

  final bool showUpcomingSection;
  final int bookedPlaceholderCount;

  @override
  Widget build(BuildContext context) {
    final upcomingCardWidth = context.width * 0.7;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (showUpcomingSection) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _SkeletonBlock(width: 100, height: 12, radius: 4),
                _SkeletonBlock(width: 44, height: 12, radius: 4),
              ],
            ),
          ),
          Gap.h18,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                ...List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                    child: UpcomingShowCardSkeleton(width: upcomingCardWidth),
                  ),
                ),
              ],
            ),
          ),
          Gap.h(36),
        ],
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SkeletonBlock(width: 120, height: 12, radius: 4),
            ),
          ],
        ),
        Gap.h20,
        for (var i = 0; i < bookedPlaceholderCount; i++) ...[
          if (i > 0) Gap.h8,
          const BookedShowItemSkeleton(),
        ],
        Gap.h(100),
      ],
    );
  }
}

/// One-column card placeholders for the redesigned tickets home tabs.
class TicketEventCardListSkeleton extends StatelessWidget {
  const TicketEventCardListSkeleton({
    super.key,
    this.count = 3,
    this.mode = TicketEventCardMode.upcoming,
  });

  final int count;
  final TicketEventCardMode mode;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: count,
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(height: 1, color: AppColors.greyTint20),
      ),
      itemBuilder: (_, __) => TicketEventCardSkeleton(mode: mode),
    );
  }
}

class TicketEventCardSkeleton extends StatelessWidget {
  const TicketEventCardSkeleton({
    super.key,
    this.mode = TicketEventCardMode.upcoming,
  });

  final TicketEventCardMode mode;

  static const double _heroHeight = 225;

  @override
  Widget build(BuildContext context) {
    final isPurchased = mode == TicketEventCardMode.purchased;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            const _SkeletonBlock(height: _heroHeight, radius: 16),
            if (isPurchased)
              const Positioned(
                top: 12,
                left: 12,
                child: _SkeletonBlock(width: 88, height: 32, radius: 100),
              ),
          ],
        ),
        Gap.h12,
        const _SkeletonLine(widthFactor: 0.72, height: 16),
        Gap.h8,
        Row(
          children: [
            const _SkeletonBlock(width: 14, height: 14, radius: 2),
            Gap.w6,
            const _SkeletonBlock(width: 120, height: 12, radius: 4),
            Gap.w12,
            const _SkeletonBlock(width: 14, height: 14, radius: 2),
            Gap.w6,
            const _SkeletonBlock(width: 64, height: 12, radius: 4),
          ],
        ),
        Gap.h8,
        const _SkeletonLine(widthFactor: 1, height: 14),
        Gap.h6,
        const _SkeletonLine(widthFactor: 0.88, height: 14),
        if (!isPurchased) ...[
          Gap.h14,
          Row(
            children: const [
              Expanded(child: _SkeletonBlock(height: 52, radius: 100)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBlock(height: 52, radius: 100)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Mirrors [UpcomingShowsComponent] on the ticket strip (image, title, time).
class UpcomingShowCardSkeleton extends StatelessWidget {
  const UpcomingShowCardSkeleton({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBlock(width: width, height: 130, radius: 12),
          Gap.h8,
          const _SkeletonLine(widthFactor: 0.92, height: 14),
          Gap.h4,
          const _SkeletonLine(widthFactor: 0.55, height: 14),
          Gap.h10,
          Row(
            children: [
              const _SkeletonBlock(width: 11, height: 11, radius: 2),
              Gap.w4,
              const _SkeletonBlock(width: 96, height: 10, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mirrors [BookedShowsComponent] (88×88 thumb, title, description, meta, divider).
class BookedShowItemSkeleton extends StatelessWidget {
  const BookedShowItemSkeleton({super.key});

  static const double _thumbSize = 88;
  static const double _thumbRadius = 12;
  static const double _horizontalPadding = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _SkeletonBlock(
                width: _thumbSize,
                height: _thumbSize,
                radius: _thumbRadius,
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _SkeletonLine(widthFactor: 0.72, height: 14),
                    Gap.h10,
                    const _SkeletonLine(widthFactor: 1, height: 12),
                    Gap.h10,
                    Row(
                      children: [
                        const _SkeletonBlock(width: 100, height: 10, radius: 4),
                        Gap.w12,
                        const _SkeletonBlock(width: 56, height: 10, radius: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h16,
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.greyTint15,
          ),
        ],
      ),
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
