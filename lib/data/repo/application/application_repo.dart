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

  Future<ApiResponse<InterviewPickerData>> getInterviewSlots();

  Future<ApiResponse<InterviewBookingConfirmation>>
  postApplicantInterviewBooking({required String slotUid});

  Future<ApiResponse<ApplicantSchedulePayload>> getApplicantSchedule();

  Future<ApiResponse<CurrentInterviewBookingPayload>>
  getCurrentInterviewBooking();
}
