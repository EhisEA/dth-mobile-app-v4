import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Wraps the interview slot in `<b>` when the API sends plain text like
/// "You selected 12th May, 2026 5:00PM for your virtual interview."
String _scheduleBodyWithBoldSelectionSlot(String body) {
  final s = body.trim();
  if (s.isEmpty) return s;
  if (RegExp(r"<\s*/?\s*(b|u|i|em)\s*>", caseSensitive: false).hasMatch(s)) {
    return s;
  }
  final m = RegExp(
    r"^((?:[Yy]ou\s+)?[Ss]elected\s+)(.+?)(\s+for\s+your\b)",
    caseSensitive: false,
  ).firstMatch(s);
  if (m == null) return s;
  final slot = m.group(2) ?? "";
  if (slot.isEmpty) return s;
  return "${m.group(1)}<b>$slot</b>${m.group(3)}${s.substring(m.end)}";
}

/// Schedule list from `GET /applicant/schedule` `data` payload.
Future<void> showApplicantScheduleSheet(
  BuildContext context, {
  required ApplicantSchedulePayload payload,
  Future<void> Function(JourneyCta cta)? onEventCta,
}) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (ctx) =>
        _ApplicantScheduleSheetBody(payload: payload, onEventCta: onEventCta),
  );
}

bool _scheduleCtaIsInterviewLink(JourneyCta cta) {
  return cta.action.toLowerCase().trim() == "open_sheet" &&
      cta.target.toLowerCase().trim() == "interview_link";
}

class _ApplicantScheduleSheetBody extends StatefulWidget {
  const _ApplicantScheduleSheetBody({required this.payload, this.onEventCta});

  final ApplicantSchedulePayload payload;
  final Future<void> Function(JourneyCta cta)? onEventCta;

  @override
  State<_ApplicantScheduleSheetBody> createState() =>
      _ApplicantScheduleSheetBodyState();
}

class _ApplicantScheduleSheetBodyState
    extends State<_ApplicantScheduleSheetBody> {
  /// Row index whose CTA is awaiting [onEventCta] (e.g. interview link fetch).
  int? _pendingCtaEventIndex;

  Widget _leadingIcon(ScheduleEvent e) {
    final ic = e.icon.toLowerCase().trim();
    final IconData data = switch (ic) {
      "check" => Icons.check,
      "clock" => Icons.schedule,
      _ => Icons.circle,
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.greyTint15,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          height: 15,
          width: 15,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(data, color: Colors.white, size: ic == "check" ? 10 : 10),
        ),
      ),
    );
  }

  Widget? _eventCtaButton(ScheduleEvent e, int eventIndex) {
    final cta = e.cta;
    if (cta == null || cta.label.trim().isEmpty) return null;
    final v = cta.variant.toLowerCase().trim();
    final rowBusy = cta.isLoading || _pendingCtaEventIndex == eventIndex;
    final canInvoke =
        cta.enabled && !cta.isLoading && widget.onEventCta != null;

    Future<void> onTap() async {
      HapticFeedback.lightImpact();
      final cb = widget.onEventCta;
      if (cb == null) return;
      if (_scheduleCtaIsInterviewLink(cta)) {
        setState(() => _pendingCtaEventIndex = eventIndex);
        try {
          await cb(cta);
        } finally {
          if (mounted) setState(() => _pendingCtaEventIndex = null);
        }
      } else {
        await cb(cta);
      }
    }

    if (v == "ghost") {
      return Align(
        alignment: Alignment.centerLeft,
        child: AppButton.onBorder(
          text: cta.label,
          shrinkWrap: true,
          fontSize: 12,
          height: 36,
          radius: 100,
          color: AppColors.white,
          textColor: AppColors.black,
          borderColor: const Color(0xffEDEDED),
          borderWidth: 1,
          enabled: canInvoke,
          isLoading: rowBusy,
          press: canInvoke && !rowBusy
              ? () {
                  unawaited(onTap());
                }
              : null,
        ),
      );
    }
    if (v == "secondary") {
      return AppButton.secondary(
        text: cta.label,
        width: double.infinity,
        fontSize: 12,
        height: 36,
        radius: 100,
        enabled: canInvoke,
        isLoading: rowBusy,
        press: canInvoke && !rowBusy
            ? () {
                unawaited(onTap());
              }
            : null,
      );
    }
    return AppButton.primary(
      text: cta.label,
      width: double.infinity,
      fontSize: 12,
      height: 36,
      radius: 100,
      enabled: canInvoke,
      isLoading: rowBusy,
      press: canInvoke && !rowBusy
          ? () {
              unawaited(onTap());
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final title = widget.payload.title.trim().isNotEmpty
        ? widget.payload.title.trim()
        : "Your schedule";

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.medium(title, fontSize: 16, color: AppColors.black),
                Material(
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
              ],
            ),
            Gap.h28,
            for (var i = 0; i < widget.payload.events.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xffEDEDED),
                ),
              if (i > 0) Gap.h16,
              _ScheduleEventRow(
                event: widget.payload.events[i],
                leading: _leadingIcon(widget.payload.events[i]),
                cta: _eventCtaButton(widget.payload.events[i], i),
              ),
            ],
            Gap.h8,
          ],
        ),
      ),
    );
  }
}

class _ScheduleEventRow extends StatelessWidget {
  const _ScheduleEventRow({
    required this.event,
    required this.leading,
    this.cta,
  });

  final ScheduleEvent event;
  final Widget leading;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final dateLine = event.date.trim();
    final timeLine = event.time.trim();
    final stamp = [dateLine, timeLine].where((s) => s.isNotEmpty).join(" ");

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppText.medium(
                      event.title.trim().isNotEmpty ? event.title : "—",
                      fontSize: 14,
                      color: AppColors.black,
                      maxLines: 3,
                      multiText: true,
                    ),
                  ),
                  if (stamp.isNotEmpty) ...[
                    SizedBox(
                      width: 80,
                      child: AppText.regular(
                        stamp,
                        fontSize: 10,
                        color: AppColors.blackTint20,
                        maxLines: 3,
                        multiText: true,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ],
              ),
              if (event.body.trim().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: InlineTaggedText(
                    _scheduleBodyWithBoldSelectionSlot(event.body),
                    color: AppColors.blackTint20,
                    strongColor: AppColors.black,
                    fontSize: 10,
                    maxLines: 5,
                    height: 1.4,
                  ),
                ),
              ],
              if (cta != null) ...[Gap.h16, cta!],
              Gap.h20,
            ],
          ),
        ),
      ],
    );
  }
}
