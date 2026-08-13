import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/view_model/ticket_home_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

class TicketHomeToggle extends StatelessWidget {
  const TicketHomeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TicketHomeTab selected;
  final ValueChanged<TicketHomeTab> onChanged;

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
              label: "Upcoming",
              isActive: selected == TicketHomeTab.upcoming,
              onTap: () => _select(TicketHomeTab.upcoming),
            ),
          ),
          Gap.w4,
          Expanded(
            child: _Segment(
              label: "Purchased",
              isActive: selected == TicketHomeTab.purchased,
              onTap: () => _select(TicketHomeTab.purchased),
            ),
          ),
        ],
      ),
    );
  }

  void _select(TicketHomeTab next) {
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
            color: isActive ? AppColors.white : AppColors.black,
            maxLines: 1,
            height: 1.2,
            letterSpacing: -0.2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
