import "package:dth_v4/data/data.dart";
import "package:flutter_utils/flutter_utils.dart";

abstract class ApplicationRepo {
  Future<ApiResponse> submitApplication(ApplicationSubmitRequest request);

  Future<ApiResponse<ApplicationProcess>> getApplicationProcess();

  Future<ApiResponse<ApplicantDashboardData>> getApplicantDashboard();

  Future<ApiResponse<void>> postApplicantAuditionVideos({
    required String videoLink,
    required String socialMediaLink,
  });

  /// Submits the `info_required` journey form. [answers] is keyed by
  /// `InfoFormField.key`; wrapped as `{ "answers": answers }` by the impl.
  Future<ApiResponse<void>> postApplicantInfoForm({
    required Map<String, dynamic> answers,
  });

  /// Saves a partial draft of the info form (called on each step Proceed).
  /// Same `{ "answers": answers }` shape as [postApplicantInfoForm].
  Future<ApiResponse<void>> postApplicantInfoFormFields({
    required Map<String, dynamic> answers,
  });

  /// [date] when set is sent as `?date=YYYY-MM-DD` to load times for that day.
  Future<ApiResponse<InterviewPickerData>> getInterviewSlots({String? date});

  Future<ApiResponse<InterviewBookingConfirmation>>
  postApplicantInterviewBooking({required String slotUid});

  Future<ApiResponse<ApplicantSchedulePayload>> getApplicantSchedule();

  Future<ApiResponse<CurrentInterviewBookingPayload>>
  getCurrentInterviewBooking();
}
