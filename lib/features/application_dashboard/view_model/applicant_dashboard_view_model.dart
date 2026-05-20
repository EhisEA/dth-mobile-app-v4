import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application_dashboard/bottomsheet/show_applicant_schedule_sheet.dart";
import "package:dth_v4/features/application_dashboard/bottomsheet/show_current_interview_link_sheet.dart";
import "package:dth_v4/features/application_dashboard/bottomsheet/show_interview_slots_sheet.dart";
import "package:dth_v4/features/application_dashboard/bottomsheet/show_resubmit_video_sheet.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ApplicantDashboardViewModel extends BaseChangeNotifierViewModel {
  ApplicantDashboardViewModel(this._applicationRepo, this._userProfile);

  final ApplicationRepo _applicationRepo;
  final UserProfileState _userProfile;

  ApplicantDashboardData? _data;

  ApplicantDashboardData? get data => _data;

  String? _interviewSlotsFetchCardKey;
  String? _scheduleFetchCardKey;
  String? _interviewLinkFetchCardKey;

  bool _silentDashboardBootstrapInFlight = false;

  /// True while [getInterviewSlots] is running for the interview picker opened
  /// from the journey card with this [journeyCardKey].
  bool interviewSlotsFetchBusyFor(String journeyCardKey) =>
      _interviewSlotsFetchCardKey == journeyCardKey;

  /// True while [getCurrentInterviewBooking] is running for the meeting-link sheet
  /// opened from the journey card with this [journeyCardKey] (e.g. `interview`).
  bool interviewLinkFetchBusyFor(String journeyCardKey) =>
      _interviewLinkFetchCardKey == journeyCardKey;

  /// True while [getApplicantSchedule] is running after tapping the schedule card.
  bool scheduleFetchBusyFor(String journeyCardKey) =>
      _scheduleFetchCardKey == journeyCardKey;

  /// Same role gate as the home apply banner; errors are silent (no baseState / toast).
  Future<void> prefetchForHomeUser() async {
    final user = _userProfile.user.value;
    if (user != null && user.participationRole != ParticipationRole.user) {
      return;
    }
    await _reloadApplicantDashboard(showErrorOnFailure: false);
  }

  /// After a successful application submit — same fetch as [refreshDashboard]
  /// but **silent** on failure so the submit success UX is not undermined (home
  /// may still read updated [data] when this succeeds).
  Future<void> refreshAfterApplicationSubmit() async {
    await _reloadApplicantDashboard(showErrorOnFailure: false);
  }

  /// Pull-to-refresh: does not set global busy (keeps current body visible).
  Future<void> refreshDashboard() async {
    await _reloadApplicantDashboard(
      showErrorOnFailure: true,
      setErrorStateIfFailureAndEmpty: false,
    );
  }

  /// Screen init (and Retry): silent GET — no [baseState] busy; stale data stays
  /// visible while refreshing; cold failure uses [ViewModelState.error].
  Future<void> bootstrapDashboardSilently() async {
    if (_silentDashboardBootstrapInFlight) return;
    _silentDashboardBootstrapInFlight = true;
    try {
      final hadData = _data != null;
      if (baseState.isError) {
        changeBaseState(const ViewModelState.idle());
        notifyListeners();
      }
      await _reloadApplicantDashboard(
        showErrorOnFailure: hadData,
        setErrorStateIfFailureAndEmpty: true,
      );
    } finally {
      _silentDashboardBootstrapInFlight = false;
    }
  }

  Future<void> _reloadApplicantDashboard({
    required bool showErrorOnFailure,
    bool setErrorStateIfFailureAndEmpty = false,
  }) async {
    final hadData = _data != null;
    try {
      final response = await _applicationRepo.getApplicantDashboard();
      _data = response.data;
      changeBaseState(const ViewModelState.idle());
      notifyListeners();
    } on ApiFailure catch (e) {
      if (setErrorStateIfFailureAndEmpty && !hadData && _data == null) {
        changeBaseState(ViewModelState.error(e));
      } else if (showErrorOnFailure) {
        DthFlushBar.instance.showError(message: e.message, title: "Failed");
      }
      notifyListeners();
    }
  }

  String appBarTitle(ApplicantDashboardData? d) {
    final t = d?.header?.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return "Applicant Dashboard";
  }

  String performanceCaption(ApplicantDashboardData d) {
    final c = d.performance.caption?.trim();
    if (c != null && c.isNotEmpty) return c;
    return "Based on reviewer evaluations";
  }

  String journeySectionTitle(ApplicantDashboardData d) {
    final t = d.journey.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final s = d.journey.stage?.trim();
    if (s != null && s.isNotEmpty) return s;
    return "Your Journey";
  }

  Color bannerBackgroundForVariant(String variant) {
    switch (variant.toLowerCase()) {
      case "success":
        return AppColors.primary.withValues(alpha: 0.08);
      case "warning":
        return AppColors.secondaryOrange.withValues(alpha: 0.12);
      case "danger":
      case "error":
        return AppColors.redTint35.withValues(alpha: 0.08);
      default:
        return AppColors.greyTint20;
    }
  }

  String iconForVariant(String variant) {
    switch (variant.toLowerCase()) {
      case "success":
        return SvgAssets.check;
      case "danger":
        return SvgAssets.infoOutline;
      default:
        return SvgAssets.check;
    }
  }

  Color bannerBodyTextColorForVariant(String variant) {
    switch (variant.toLowerCase()) {
      case "success":
        return AppColors.primaryMedium;
      case "danger":
      case "error":
        return AppColors.redTint35;
      default:
        return AppColors.blackTint20;
    }
  }

  /// Top background image behind the app bar; follows [footerBanner.variant].
  /// `danger` / `error` → red, `success` → green, otherwise (incl. no banner) → blue.
  String applicantDashboardHeaderBackgroundAsset(ApplicantDashboardData? d) {
    final v = (d?.footerBanner?.variant ?? "").trim().toLowerCase();
    if (v == "danger" || v == "error") {
      return ImageAssets.redBg;
    }
    if (v == "success") {
      return ImageAssets.greenBg;
    }
    return ImageAssets.blueBg;
  }

  void handleBack(BuildContext context) {
    final action = _data?.header?.backAction;
    if (action == "navigate:home") {
      MobileNavigationService.instance.goBack();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void handleJourneyCta(BuildContext context, JourneyCard card) {
    final cta = card.cta;
    if (cta == null || !cta.enabled || cta.label.isEmpty) return;
    if (cta.isLoading) return;

    final target = cta.target.toLowerCase();
    final action = cta.action.toLowerCase();
    if (action == "open_sheet" && target == "resubmit_video") {
      unawaited(
        showResubmitVideoSheet(
          context,
          onSubmit: (videoLink, socialMediaLink) => _submitAuditionResubmission(
            context,
            videoLink: videoLink,
            socialMediaLink: socialMediaLink,
          ),
        ),
      );
      return;
    }
    if (action == "open_sheet" && target == "interview_slots") {
      unawaited(_openInterviewSlotsFromCard(context, card));
      return;
    }
    if (action == "external" && target == "meeting_link") {
      unawaited(_openMeetingLinkFromJourneyCard(context, card.key));
      return;
    }
    if (target == "application_form" || action == "submit") {
      MobileNavigationService.instance.navigateTo(NavigatorRoutes.application);
    }
  }

  Future<void> _openInterviewSlotsFromCard(
    BuildContext context,
    JourneyCard card,
  ) async {
    _interviewSlotsFetchCardKey = card.key;
    notifyListeners();
    try {
      final r = await _applicationRepo.getInterviewSlots();
      final data = r.data;
      if (data == null) throw ApiFailure("No data");
      if (!context.mounted) return;

      Future<InterviewPickerData> loadPicker() async {
        final r2 = await _applicationRepo.getInterviewSlots();
        final d = r2.data;
        if (d == null) throw ApiFailure("No data");
        return d;
      }

      await showInterviewSlotsSheet(
        context,
        preloadedData: data,
        loadPicker: loadPicker,
        bookSlot: (slotUid) async {
          final br = await _applicationRepo.postApplicantInterviewBooking(
            slotUid: slotUid,
          );
          final c = br.data;
          if (c == null) throw ApiFailure("No data");
          return c;
        },
        onBookedRefreshDashboard: refreshDashboard,
        onInterviewConfirmationDismiss: () async {
          if (!context.mounted) return;
          DthFlushBar.instance.showSuccess(
            title: "Success",
            message: "Interview booked.",
          );
        },
      );
    } on ApiFailure catch (e) {
      if (context.mounted) {
        DthFlushBar.instance.showError(message: e.message, title: "Failed");
      }
    } finally {
      _interviewSlotsFetchCardKey = null;
      notifyListeners();
    }
  }

  /// Opens schedule bottom sheet after [getApplicantSchedule]; no-op if [events] empty.
  Future<void> openScheduleSheet(BuildContext context) async {
    const scheduleKey = "schedule";
    _scheduleFetchCardKey = scheduleKey;
    notifyListeners();
    try {
      final r = await _applicationRepo.getApplicantSchedule();
      final p = r.data;
      if (!context.mounted) return;
      if (p == null) throw ApiFailure("No data");
      if (p.events.isEmpty) return;
      await showApplicantScheduleSheet(
        context,
        payload: p,
        onEventCta: (cta) async => _handleScheduleEventCta(context, cta),
      );
    } on ApiFailure catch (e) {
      if (context.mounted) {
        DthFlushBar.instance.showError(message: e.message, title: "Failed");
      }
    } finally {
      _scheduleFetchCardKey = null;
      notifyListeners();
    }
  }

  Future<CurrentInterviewBookingPayload>
  _loadCurrentInterviewBookingPayload() async {
    final r = await _applicationRepo.getCurrentInterviewBooking();
    final payload = r.data;
    if (payload == null) throw ApiFailure("No data");
    return payload;
  }

  Future<void> _openMeetingLinkFromJourneyCard(
    BuildContext context,
    String cardKey,
  ) async {
    _interviewLinkFetchCardKey = cardKey;
    notifyListeners();
    try {
      final payload = await _loadCurrentInterviewBookingPayload();
      if (!context.mounted) return;
      await showCurrentInterviewLinkSheet(context, payload: payload);
    } on ApiFailure catch (e) {
      if (context.mounted) {
        DthFlushBar.instance.showError(message: e.message, title: "Failed");
      }
    } finally {
      _interviewLinkFetchCardKey = null;
      notifyListeners();
    }
  }

  /// Row actions inside the schedule sheet; extend when product defines flows.
  Future<void> _handleScheduleEventCta(
    BuildContext context,
    JourneyCta cta,
  ) async {
    if (!cta.enabled || cta.label.isEmpty) return;
    final target = cta.target.toLowerCase();
    final action = cta.action.toLowerCase();
    if (action == "open_sheet" && target == "interview_link") {
      try {
        final payload = await _loadCurrentInterviewBookingPayload();
        if (!context.mounted) return;
        Navigator.of(context).pop();
        await refreshDashboard();
        if (!context.mounted) return;
        await showCurrentInterviewLinkSheet(context, payload: payload);
      } on ApiFailure catch (e) {
        if (context.mounted) {
          DthFlushBar.instance.showError(message: e.message, title: "Failed");
        }
      }
      return;
    }
    DthFlushBar.instance.showGeneric(
      title: "Action",
      message: "Unsupported action: ${cta.action} / ${cta.target}",
    );
  }

  Future<void> _submitAuditionResubmission(
    BuildContext context, {
    required String videoLink,
    required String socialMediaLink,
  }) async {
    try {
      await _applicationRepo.postApplicantAuditionVideos(
        videoLink: videoLink,
        socialMediaLink: socialMediaLink,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await refreshDashboard();
      if (!context.mounted) return;
      DthFlushBar.instance.showSuccess(
        title: "Success",
        message: "Resubmission received.",
      );
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Failed");
    }
  }

  /// Pairs of cards for a two-column grid; second slot may be null (odd count).
  List<List<JourneyCard?>> journeyGridRows(ApplicantDashboardData d) {
    final cards = d.journey.displayCards;
    final rows = <List<JourneyCard?>>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add([cards[i], if (i + 1 < cards.length) cards[i + 1] else null]);
    }
    return rows;
  }
}

final applicantDashboardViewModelProvider =
    ChangeNotifierProvider<ApplicantDashboardViewModel>((ref) {
      return ApplicantDashboardViewModel(
        ref.read(applicationRepositoryProvider),
        ref.read(userProfileStateProvider),
      );
    });
