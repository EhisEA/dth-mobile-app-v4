import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/models/user_model.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class ContestantPill extends StatelessWidget {
  const ContestantPill({super.key, this.user});

  final UserModel? user;

  static const _chipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  static const _pillRadius = 100.0;

  @override
  Widget build(BuildContext context) {
    final role = user?.participationRole ?? ParticipationRole.user;
    switch (role) {
      case ParticipationRole.contestant:
        final u = user;
        if (u == null) return const SizedBox.shrink();
        return _withProfileSpacing(
          _UnifiedDualPill(
            label: 'CONTESTANT',
            user: u,
            padding: _chipPadding,
            radius: _pillRadius,
          ),
        );
      case ParticipationRole.applicant:
        final u = user;
        if (u == null) return const SizedBox.shrink();
        return _withProfileSpacing(
          _UnifiedDualPill(
            label: 'APPLICANT',
            user: u,
            padding: _chipPadding,
            radius: _pillRadius,
          ),
        );
      case ParticipationRole.user:
      case ParticipationRole.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _withProfileSpacing(Widget pill) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Gap.h16, pill],
    );
  }
}

class _UnifiedDualPill extends StatelessWidget {
  const _UnifiedDualPill({
    required this.label,
    required this.user,
    required this.padding,
    required this.radius,
  });

  final String label;
  final UserModel user;
  final EdgeInsets padding;
  final double radius;

  static final _dividerColor = AppColors.greyTint30;
  static final _borderColor = AppColors.greyTint30;

  String _displayUid(String raw) {
    if (raw.isEmpty) return '—';
    return raw.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final id = user.participationType.id;
    final display = _displayUid(id ?? '');
    final canCopy = id != null && id.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (!w.isFinite || w <= 0) {
          return const SizedBox.shrink();
        }
        // Room for label + divider + paddings + copy icon; id truncates if needed.
        const leftAndChromeReserve = 132.0;
        final idMaxWidth = (w - leftAndChromeReserve).clamp(72.0, 280.0);

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: _borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: padding,
                  child: AppText.medium(
                    label,
                    fontSize: 10,
                    color: AppColors.mainBlack,
                    letterSpacing: 0.4,
                  ),
                ),
                Container(width: 1, height: 12, color: _dividerColor),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canCopy
                        ? () {
                            final raw = user.participationType.id;
                            if (raw == null || raw.isEmpty) return;
                            Clipboard.setData(ClipboardData(text: raw));
                            HapticFeedback.lightImpact();
                            DthFlushBar.instance.showCopySuccess(
                              title: "Copied to clipboard",
                              message:
                                  "The ID has been copied to your clipboard",
                            );
                          }
                        : null,
                    child: Padding(
                      padding: padding,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: idMaxWidth),
                            child: AppText.medium(
                              display,
                              fontSize: 10,
                              color: AppColors.mainBlack,
                              letterSpacing: 0.4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canCopy) ...[
                            Gap.w4,
                            SvgPicture.asset(
                              SvgAssets.copyOutline,
                              width: 14,
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
