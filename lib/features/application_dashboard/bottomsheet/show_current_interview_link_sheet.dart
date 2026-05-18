import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Static tips when API omits [CurrentInterviewBookingPayload.instructions].
const List<String> _kInterviewTips = [
  "Copy the interview link using the copy button, then paste it into your browser or meeting app to join.",
  "Join the session at least 5 minutes before your scheduled time.",
  "Ensure your audio and video are enabled and working correctly before joining.",
  "Position yourself in a well-lit, distraction-free environment.",
  "Ensure you have a reliable internet connection for a smooth interview experience.",
];

/// `GET /applicant/interview-bookings/current` — join URL, countdown, tips, dismiss.
Future<void> showCurrentInterviewLinkSheet(
  BuildContext context, {
  required CurrentInterviewBookingPayload payload,
}) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (ctx) => _CurrentInterviewLinkSheetBody(payload: payload),
  );
}

String _countdownLine(CurrentInterviewBookingPayload p) {
  final api = p.countdownLabel.trim();
  if (api.isNotEmpty) return api;
  return _startsInLine(p);
}

String _startsInLine(CurrentInterviewBookingPayload p) {
  final start = p.startsAt;
  if (start == null) {
    return p.subtitle.trim();
  }
  final now = DateTime.now().toUtc();
  final s = start.toUtc();
  if (!s.isAfter(now)) {
    final sub = p.subtitle.trim();
    return sub.isNotEmpty ? sub : "Starting soon";
  }
  var diff = s.difference(now);
  final days = diff.inDays;
  diff -= Duration(days: days);
  final hours = diff.inHours;
  diff -= Duration(hours: hours);
  final mins = diff.inMinutes;
  final parts = <String>[];
  if (days > 0) {
    parts.add("$days ${days == 1 ? "day" : "days"}");
  }
  if (hours > 0) {
    parts.add("$hours ${hours == 1 ? "hour" : "hours"}");
  }
  if (mins > 0 || parts.isEmpty) {
    parts.add("$mins ${mins == 1 ? "min" : "mins"}");
  }
  return "Starts in ${parts.join(" ")}";
}

List<Widget> _credentialsSection(CurrentInterviewBookingPayload payload) {
  final c = payload.credentials;
  if (c == null || !c.hasDetails) return const [];
  final hasUser = c.username.trim().isNotEmpty;
  final hasPass = c.password.trim().isNotEmpty;
  return [
    Gap.h20,
    Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasUser)
              Expanded(
                child: _InterviewCredentialCell(
                  label: "Username:",
                  value: c.username.trim(),
                  copiedMessage: "Username copied to clipboard.",
                  end: true,
                ),
              ),
            if (hasUser && hasPass) const SizedBox(width: 16),
            if (hasPass)
              Expanded(
                child: _InterviewCredentialCell(
                  label: "Password:",
                  value: c.password.trim(),
                  copiedMessage: "Password copied to clipboard.",
                  end: false,
                ),
              ),
          ],
        ),
      ),
    ),
  ];
}

class _InterviewCredentialCell extends StatelessWidget {
  const _InterviewCredentialCell({
    required this.label,
    required this.value,
    required this.copiedMessage,
    this.end = true,
  });

  final String label;
  final String value;
  final String copiedMessage;
  final bool end;

  static const double _copySize = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.regular(
          label,
          fontSize: 8,
          height: 1.2,
          color: AppColors.blackTint20,
          letterSpacing: -0.2,
        ),
        Gap.h2,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: end
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            AppText.semiBold(
              value,
              fontSize: 12,
              height: 1.25,
              color: AppColors.mainBlack,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              multiText: true,
            ),
            Gap.w6,
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  HapticFeedback.lightImpact();
                  DthFlushBar.instance.showCopySuccess(
                    title: "Copied",
                    message: copiedMessage,
                  );
                },
                customBorder: const CircleBorder(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(
                    SvgAssets.copyOutline,
                    width: _copySize,
                    height: _copySize,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentInterviewLinkSheetBody extends StatelessWidget {
  const _CurrentInterviewLinkSheetBody({required this.payload});

  final CurrentInterviewBookingPayload payload;

  void _onPrimary(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final join = payload.joinUrl.trim();
    final canCopy = join.isNotEmpty;
    final countdown = _countdownLine(payload).trim();
    final tips = payload.instructions.isNotEmpty
        ? payload.instructions
        : _kInterviewTips;
    final headerLabel = payload.title.trim().isNotEmpty
        ? payload.title.trim()
        : "Your interview link:";
    final sheetCta = payload.cta;
    final rawPrimary = (sheetCta?.label ?? "").trim();
    final primaryLabel = rawPrimary.isNotEmpty
        ? rawPrimary
        : "Alright. Got it!";
    final primaryEnabled = sheetCta?.enabled ?? true;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: AppColors.greyTint20,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).maybePop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.mainBlack,
                    ),
                  ),
                ),
              ),
            ),
            Gap.h8,
            AppText.regular(
              headerLabel,
              fontSize: 12,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
              multiText: true,
            ),
            Gap.h4,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                canCopy
                    ? AppText.medium(
                        join,
                        fontSize: 16,
                        color: AppColors.black,
                        multiText: true,
                        maxLines: 8,
                      )
                    : AppText.medium(
                        "—",
                        fontSize: 16,
                        color: AppColors.blackTint20,
                      ),
                if (canCopy) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: join));
                        HapticFeedback.lightImpact();
                        DthFlushBar.instance.showCopySuccess(
                          title: "Copied",
                          message: "Interview link copied to clipboard.",
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: SvgPicture.asset(
                          SvgAssets.copyOutline,
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (countdown.isNotEmpty) ...[
              Gap.h8,
              AppText.regular(
                countdown,
                fontSize: 10,
                color: AppColors.blackTint20,
                textAlign: TextAlign.center,
                multiText: true,
              ),
            ],
            ..._credentialsSection(payload),
            Gap.h20,
            Container(
              decoration: BoxDecoration(
                color: const Color(0xffF6F8FE),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText.medium(
                    "What you need to know:",
                    fontSize: 10,
                    color: AppColors.dthBlue,
                    textAlign: TextAlign.center,
                    multiText: true,
                  ),
                  Gap.h20,
                  for (var i = 0; i < tips.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xffEDEDED),
                      ),
                    if (i > 0) Gap.h12,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(SvgAssets.doubleTick),
                        Gap.w16,
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: AppText.regular(
                              tips[i],
                              fontSize: 12,
                              color: AppColors.black,
                              height: 1.35,
                              multiText: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i < tips.length - 1) Gap.h12,
                  ],
                ],
              ),
            ),
            Gap.h24,
            AppButton.primary(
              text: primaryLabel,
              width: double.infinity,
              height: 48,
              radius: 100,
              enabled: primaryEnabled,
              press: primaryEnabled ? () => _onPrimary(context) : null,
            ),
            Gap.h8,
          ],
        ),
      ),
    );
  }
}
