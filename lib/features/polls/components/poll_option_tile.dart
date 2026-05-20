import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/features/polls/components/poll_option_data.dart';
import 'package:dth_v4/features/polls/components/poll_progress_bar.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/flutter_utils.dart';

class PollOptionTile extends StatelessWidget {
  const PollOptionTile({
    super.key,
    required this.data,
    this.onTap,
    this.enabled = true,
    this.isBusy = false,
  });

  final PollOptionData data;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isBusy && onTap != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: GestureDetector(
            onTap: canTap ? onTap : null,
            child: Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: data.selected
                      ? AppColors.primary
                      : AppColors.tint5.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: isBusy
                  ? Center(
                      child: SizedBox(
                        height: 9,
                        width: 9,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.3,
                          color: data.selected
                              ? Colors.white
                              : AppColors.blackTint20,
                        ),
                      ),
                    )
                  : data.selected
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppText.regular(
                      data.title,
                      fontSize: 12,
                      color: AppColors.black,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  Gap.w8,

                  AppText.regular(
                    '${data.percentage}%',
                    fontSize: 10,
                    color: AppColors.black,
                    letterSpacing: -0.25,
                  ),
                ],
              ),
              Gap.h4,
              PollProgressBar(
                progress: data.progress,
                isSelected: data.selected,
                pollHasVoted: data.pollHasVoted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
