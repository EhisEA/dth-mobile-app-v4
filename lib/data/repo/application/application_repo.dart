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

  Future<ApiResponse<InterviewPickerData>> getInterviewSlots();

  Future<ApiResponse<InterviewBookingConfirmation>>
  postApplicantInterviewBooking({required String slotUid});

  Future<ApiResponse<ApplicantSchedulePayload>> getApplicantSchedule();

  Future<ApiResponse<CurrentInterviewBookingPayload>>
  getCurrentInterviewBooking();
}
