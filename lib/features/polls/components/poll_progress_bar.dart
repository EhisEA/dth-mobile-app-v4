import 'package:dth_v4/core/core.dart';
import 'package:flutter/material.dart';

class PollProgressBar extends StatelessWidget {
  const PollProgressBar({
    super.key,
    required this.progress,
    required this.isSelected,
    required this.pollHasVoted,
  });

  final double progress;
  final bool isSelected;
  final bool pollHasVoted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clampedProgress = progress.clamp(0.0, 1.0);
        final fillColor = !pollHasVoted
            ? AppColors.primary
            : (isSelected ? AppColors.primary : AppColors.tint10);
        return Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.greyTint30,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clampedProgress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Container(
                width: constraints.maxWidth * value,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
