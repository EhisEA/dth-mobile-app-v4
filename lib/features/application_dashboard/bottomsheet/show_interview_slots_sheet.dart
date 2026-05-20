import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

enum _InterviewInlineSlot { date, time }

const String _kSelectDateTimeToProceed = "Select date and time to proceed";
const String _kAlrightDefault = "Alright. Got it!";

/// Opens the interview picker sheet; after a successful POST the dashboard is
/// refreshed via [onBookedRefreshDashboard] **before** the confirmation sheet
/// is shown. Optional [onInterviewConfirmationDismiss] runs after the user taps
/// the confirmation primary button (e.g. success toast).
Future<void> showInterviewSlotsSheet(
  BuildContext anchorContext, {
  InterviewPickerData? preloadedData,
  required Future<InterviewPickerData> Function() loadPicker,
  required Future<InterviewBookingConfirmation> Function(String slotUid)
  bookSlot,
  required Future<void> Function() onBookedRefreshDashboard,
  Future<void> Function()? onInterviewConfirmationDismiss,
}) {
  return showBlurredModalBottomSheet<void>(
    context: anchorContext,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (sheetContext) => _InterviewSlotsSheetBody(
      anchorContext: anchorContext,
      preloadedData: preloadedData,
      loadPicker: loadPicker,
      bookSlot: bookSlot,
      onBookedRefreshDashboard: onBookedRefreshDashboard,
      onInterviewConfirmationDismiss: onInterviewConfirmationDismiss,
    ),
  );
}

Future<void> showInterviewBookedSheet(
  BuildContext context, {
  required InterviewBookingConfirmation confirmation,
  Future<void> Function()? onDismiss,
}) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (ctx) =>
        _InterviewBookedBody(confirmation: confirmation, onDismiss: onDismiss),
  );
}

class _InterviewBookedBody extends StatelessWidget {
  const _InterviewBookedBody({required this.confirmation, this.onDismiss});

  final InterviewBookingConfirmation confirmation;
  final Future<void> Function()? onDismiss;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final label = confirmation.ctaLabel?.trim().isNotEmpty == true
        ? confirmation.ctaLabel!.trim()
        : _kAlrightDefault;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
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
                      size: 14,
                      color: AppColors.mainBlack,
                    ),
                  ),
                ),
              ),
            ),
            Gap.h8,
            AppText.regular(
              confirmation.title.trim().isNotEmpty
                  ? confirmation.title
                  : "You're booked!",
              fontSize: 12,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
              multiText: true,
            ),
            Gap.h10,
            AppText.medium(
              confirmation.subtitle.trim().isNotEmpty
                  ? confirmation.subtitle
                  : "",
              fontSize: 16,
              color: AppColors.black,
              textAlign: TextAlign.center,
              maxLines: 4,
              height: 1,
              multiText: true,
            ),
            Gap.h16,
            AppText.regular(
              "We look forward to speaking with you",
              fontSize: 12,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
              multiText: true,
            ),
            Gap.h24,
            AppButton.primary(
              text: label,
              width: double.infinity,
              height: 48,
              radius: 100,
              press: () async {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                await onDismiss?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewSlotsSheetBody extends StatefulWidget {
  const _InterviewSlotsSheetBody({
    required this.anchorContext,
    this.preloadedData,
    required this.loadPicker,
    required this.bookSlot,
    required this.onBookedRefreshDashboard,
    this.onInterviewConfirmationDismiss,
  });

  final BuildContext anchorContext;
  final InterviewPickerData? preloadedData;
  final Future<InterviewPickerData> Function() loadPicker;
  final Future<InterviewBookingConfirmation> Function(String slotUid) bookSlot;
  final Future<void> Function() onBookedRefreshDashboard;
  final Future<void> Function()? onInterviewConfirmationDismiss;

  @override
  State<_InterviewSlotsSheetBody> createState() =>
      _InterviewSlotsSheetBodyState();
}

class _InterviewSlotsSheetBodyState extends State<_InterviewSlotsSheetBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ValueNotifier<Object?> _inlineDropdownCoordinator =
      ValueNotifier<Object?>(null);

  bool _loading = true;
  bool _booking = false;
  String? _loadError;
  InterviewPickerData? _data;

  String? _dateIso;
  String? _slotUid;

  @override
  void initState() {
    super.initState();
    final pre = widget.preloadedData;
    if (pre != null) {
      _applyLoaded(pre);
    } else {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _inlineDropdownCoordinator.dispose();
    super.dispose();
  }

  void _applyLoaded(InterviewPickerData d) {
    _inlineDropdownCoordinator.value = null;
    final emptyTimes = _showEmptyTimesUi(d);
    setState(() {
      _data = d;
      _dateIso = _initialDateIso(d);
      _slotUid = emptyTimes ? null : _initialSlotUid(d);
      _loadError = null;
      _loading = false;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final d = await widget.loadPicker();
      if (!mounted) return;
      _applyLoaded(d);
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = "Something went wrong";
      });
    }
  }

  String? _initialDateIso(InterviewPickerData d) {
    for (final x in d.dates) {
      if (x.selected && x.available && x.date.isNotEmpty) return x.date;
    }
    return null;
  }

  String? _initialSlotUid(InterviewPickerData d) {
    for (final x in d.times) {
      if (x.selected && x.available && x.slotUid.isNotEmpty) {
        return x.slotUid;
      }
    }
    return null;
  }

  bool _showEmptyTimesUi(InterviewPickerData d) {
    if (d.emptyState != null && d.emptyState!.hasContent) return true;
    return !d.times.any((t) => t.available && t.slotUid.isNotEmpty);
  }

  Future<void> _onSubmit() async {
    final d = _data;
    if (d == null) return;
    if (_dateIso == null || _slotUid == null) {
      DthFlushBar.instance.showError(
        title: "Missing",
        message: "Please select a date and time.",
      );
      return;
    }
    if (!d.submit.enabled) return;

    setState(() => _booking = true);
    try {
      final confirmation = await widget.bookSlot(_slotUid!);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!widget.anchorContext.mounted) return;
      await widget.onBookedRefreshDashboard();
      if (!widget.anchorContext.mounted) return;
      await showInterviewBookedSheet(
        widget.anchorContext,
        confirmation: confirmation,
        onDismiss: widget.onInterviewConfirmationDismiss,
      );
    } on ApiFailure catch (e) {
      if (mounted) {
        DthFlushBar.instance.showError(message: e.message, title: "Failed");
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: bottomInset + 24,
          top: 32,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            Gap.h16,
            AppText.regular(
              "Loading available slots…",
              fontSize: 14,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: bottomInset + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.medium(
              "Could not load slots",
              fontSize: 16,
              color: AppColors.black,
              textAlign: TextAlign.center,
            ),
            Gap.h8,
            AppText.regular(
              _loadError!,
              fontSize: 13,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
              multiText: true,
            ),
            Gap.h24,
            AppButton.primary(
              text: "Try again",
              width: double.infinity,
              height: 44,
              radius: 100,
              press: () => unawaited(_load()),
            ),
            Gap.h8,
            AppButton.secondary(
              text: "Close",
              width: double.infinity,
              height: 44,
              radius: 100,
              press: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      );
    }

    final d = _data!;
    final dateOptions = d.dates
        .where((x) => x.available && x.date.isNotEmpty)
        .map((x) => AppDropdownOption<String>(value: x.date, label: x.label))
        .toList();
    final timeOptions = d.times
        .where((t) => t.available && t.slotUid.isNotEmpty)
        .map((t) => AppDropdownOption<String>(value: t.slotUid, label: t.label))
        .toList();
    final emptyTimes = _showEmptyTimesUi(d);
    final both =
        _dateIso != null &&
        _slotUid != null &&
        !emptyTimes &&
        dateOptions.isNotEmpty;
    final canSend = both && d.submit.enabled;
    final submitLabel = !both ? _kSelectDateTimeToProceed : d.submit.label;

    final empty = d.emptyState;
    final emptyTitle = empty?.title?.trim().isNotEmpty == true
        ? empty!.title!.trim()
        : "No slots available";
    final emptyBody = empty?.body?.trim().isNotEmpty == true
        ? empty!.body!.trim()
        : "There are no open times at the moment. We'll notify you when new slots are added.";

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
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
              Gap.h4,
              AppText.medium(
                d.title.trim().isNotEmpty
                    ? d.title
                    : "Pick Your Interview Time",
                fontSize: 14,
                color: AppColors.black,
                textAlign: TextAlign.center,
              ),
              Gap.h4,
              AppText.regular(
                d.subtitle.trim().isNotEmpty
                    ? d.subtitle
                    : "Choose a date and time that works for you",
                fontSize: 12,
                height: 1.35,
                color: AppColors.blackTint20,
                textAlign: TextAlign.center,
                multiText: true,
              ),
              Gap.h24,
              if (dateOptions.isEmpty)
                AppText.regular(
                  "No dates available right now.",
                  fontSize: 13,
                  color: AppColors.blackTint20,
                )
              else
                AppDropdownFormField<String>(
                  key: ValueKey<String>("date_${d.title}_${_dateIso ?? ""}"),
                  title: "Available Dates",
                  hint: "Select an available date",
                  options: dateOptions,
                  initialValue: _dateIso,
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (_) => null,
                  onChanged: (v) => setState(() => _dateIso = v),
                  presentation: AppDropdownPresentation.inlineExpand,
                  splitLabelOnDash: true,
                  inlineExpandCoordinator: _inlineDropdownCoordinator,
                  inlineExpandSlotId: _InterviewInlineSlot.date,
                ),
              Gap.h16,
              if (timeOptions.isEmpty || emptyTimes)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffEDEDED)),
                        color: AppColors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.regular(
                            "Preferred Time",
                            fontSize: 10,
                            color: AppColors.black,
                          ),
                          Gap.h8,
                          AppText.regular(
                            "Select a preferred time",
                            fontSize: 14,
                            color: const Color(0xffB5B5B5),
                          ),
                        ],
                      ),
                    ),
                    if (emptyTimes) ...[
                      Gap.h16,
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffEDEDED)),
                          color: AppColors.white,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 40,
                              color: AppColors.tint15,
                            ),
                            Gap.h12,
                            AppText.medium(
                              emptyTitle,
                              fontSize: 14,
                              color: AppColors.black,
                              textAlign: TextAlign.center,
                            ),
                            Gap.h8,
                            AppText.regular(
                              emptyBody,
                              fontSize: 12,
                              color: AppColors.blackTint20,
                              textAlign: TextAlign.center,
                              multiText: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
              else
                AppDropdownFormField<String>(
                  key: ValueKey<String>("time_${d.title}_${_slotUid ?? ""}"),
                  title: "Preferred Time",
                  hint: "Select a preferred time",
                  options: timeOptions,
                  initialValue: _slotUid,
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (_) => null,
                  onChanged: (v) => setState(() => _slotUid = v),
                  presentation: AppDropdownPresentation.inlineExpand,
                  inlineExpandCoordinator: _inlineDropdownCoordinator,
                  inlineExpandSlotId: _InterviewInlineSlot.time,
                ),
              Gap.h24,
              AppButton.primary(
                text: submitLabel,
                width: double.infinity,
                height: 48,
                radius: 100,
                enabled: canSend && !_booking,
                isLoading: _booking,
                disableBGColor: AppColors.greyTint20,
                disableTextColor: AppColors.tint15,
                press: canSend && !_booking
                    ? () => unawaited(_onSubmit())
                    : null,
              ),
              Gap.h24,
            ],
          ),
        ),
      ),
    );
  }
}
