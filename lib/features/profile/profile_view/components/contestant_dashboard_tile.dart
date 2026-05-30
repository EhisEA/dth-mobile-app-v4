import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Account Settings row for "Contestant Dashboard" with role-based subtitle
/// and trailing (chevron for plain users, status pills for applicants/contestants).
class ContestantDashboardTile extends StatelessWidget {
  const ContestantDashboardTile({
    super.key,
    required this.role,
    this.applicationStatus,
    required this.onTap,
  });

  final ParticipationRole role;
  final ApplicationStatus? applicationStatus;
  final VoidCallback onTap;

  static const _title = "Applicant Dashboard";

  String get _subtitle {
    switch (role) {
      case ParticipationRole.applicant:
      case ParticipationRole.contestant:
        return "Track the progress of your application";
      case ParticipationRole.user:
      case ParticipationRole.unknown:
        return "Apply for DTH Season 5";
    }
  }

  bool get _showChevron =>
      role == ParticipationRole.user || role == ParticipationRole.unknown;

  (Color, Color) _statusPillColors(String variant) {
    switch (variant.trim().toLowerCase()) {
      case "success":
        return (const Color(0xff008F46), const Color(0xffE5FBF0));
      case "warning":
        return (AppColors.secondaryOrange, const Color(0xFFFFF4E5));
      case "danger":
      case "error":
        return (AppColors.redTint35, const Color(0xFFFFF2F1));
      default:
        return (AppColors.dthBlue, const Color(0xFFF0F5FF));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = applicationStatus;
    Widget? statusPill;
    if (!_showChevron && status != null) {
      final colors = _statusPillColors(status.variant);
      statusPill = _StatusPill(
        label: status.label.trim(),
        foreground: colors.$1,
        background: colors.$2,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.dthBlue,
            child: SvgPicture.asset(SvgAssets.cup),
          ),
          Gap.w14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.regular(_title, fontSize: 14, color: AppColors.black),
                Gap.h2,
                AppText.regular(
                  _subtitle,
                  fontSize: 12,
                  color: AppColors.tint15,
                ),
              ],
            ),
          ),
          if (_showChevron) SvgPicture.asset(SvgAssets.rightArrow),
          if (statusPill != null) statusPill,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppText.regular(label, fontSize: 10, color: foreground),
    );
  }
}
