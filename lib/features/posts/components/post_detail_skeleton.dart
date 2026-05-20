import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class PostDetailSkeleton extends StatelessWidget {
  const PostDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _Block(height: 220, radius: 12),
        Gap.h16,
        const _HeaderBlock(),
        Gap.h12,
        const _Line(widthFactor: 1, height: 12),
        Gap.h6,
        const _Line(widthFactor: 0.85, height: 12),
        Gap.h12,
        const _ActionsBlock(),
        Gap.h24,
        const _SectionTitleBlock(),
        Gap.h16,
        const _CommentSkeleton(),
        Gap.h20,
        const _CommentSkeleton(),
        Gap.h20,
        const _CommentSkeleton(),
      ],
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Block(height: 28, width: 28, radius: 14),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Line(widthFactor: 0.5, height: 10),
              Gap.h6,
              const _Line(widthFactor: 0.3, height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionsBlock extends StatelessWidget {
  const _ActionsBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Block(width: 48, height: 14, radius: 4),
        Gap.w14,
        const _Block(width: 48, height: 14, radius: 4),
        Gap.w14,
        const _Block(width: 48, height: 14, radius: 4),
      ],
    );
  }
}

class _SectionTitleBlock extends StatelessWidget {
  const _SectionTitleBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _Block(width: 110, height: 14, radius: 4),
        _Block(width: 24, height: 12, radius: 4),
      ],
    );
  }
}

class _CommentSkeleton extends StatelessWidget {
  const _CommentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Block(height: 32, width: 32, radius: 16),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Line(widthFactor: 0.4, height: 10),
              Gap.h8,
              const _Line(widthFactor: 1, height: 10),
              Gap.h6,
              const _Line(widthFactor: 0.7, height: 10),
              Gap.h10,
              Row(
                children: [
                  const _Block(width: 32, height: 10, radius: 3),
                  Gap.w16,
                  const _Block(width: 32, height: 10, radius: 3),
                  Gap.w16,
                  const _Block(width: 32, height: 10, radius: 3),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: _Block(height: height, radius: 4),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.width, required this.height, this.radius = 6});

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
