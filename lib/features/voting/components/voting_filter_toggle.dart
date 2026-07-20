import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

class VotingFilterToggle extends StatelessWidget {
  const VotingFilterToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final VotingFilter selected;
  final ValueChanged<VotingFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF8F9FC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.greyTint25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: "Up for eviction",
              isActive: selected == VotingFilter.upForEviction,
              onTap: () => _select(VotingFilter.upForEviction),
            ),
          ),
          Gap.w4,
          Expanded(
            child: _Segment(
              label: "All contestants",
              isActive: selected == VotingFilter.allContestants,
              onTap: () => _select(VotingFilter.allContestants),
            ),
          ),
        ],
      ),
    );
  }

  void _select(VotingFilter next) {
    if (selected == next) return;
    HapticFeedback.selectionClick();
    onChanged(next);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isActive ? Colors.transparent : AppColors.greyTint25,
            ),
          ),
          alignment: Alignment.center,
          child: AppText.regular(
            label,
            fontSize: 14,
            color: isActive ? AppColors.white : const Color(0xff666666),
            maxLines: 1,
            height: 1.2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
