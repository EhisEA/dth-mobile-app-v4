import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ApplicationRepoImpl implements ApplicationRepo {
  ApplicationRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<ApiResponse> submitApplication(
    ApplicationSubmitRequest request,
  ) async {
    final response = await _networkService.post(
      ApiRoute.application,
      data: request.toJson(),
    );
    final root = response.data as Map<String, dynamic>;
    final data = root["data"];
    return ApiResponse(data: data);
  }

  @override
  Future<ApiResponse<ApplicationProcess>> getApplicationProcess() async {
    final response = await _networkService.get(ApiRoute.applicationProcess);
    final root = response.data as Map<String, dynamic>;
    final data = root["data"] as Map<String, dynamic>;
    final process = data["application_process"] as Map<String, dynamic>;
    return ApiResponse(data: ApplicationProcess.fromJson(process));
  }

  @override
  Future<ApiResponse<ApplicantDashboardData>> getApplicantDashboard() async {
    final response = await _networkService.get(ApiRoute.applicantDashboard);
    final root = response.data as Map<String, dynamic>;
    final data = root["data"] as Map<String, dynamic>;
    return ApiResponse(data: ApplicantDashboardData.fromJson(data));
  }

  @override
  Future<ApiResponse<void>> postApplicantAuditionVideos({
    required String videoLink,
    required String socialMediaLink,
  }) async {
    final response = await _networkService.post(
      ApiRoute.applicantAuditionVideos,
      data: <String, dynamic>{
        "video_link": videoLink,
        "social_media_link": socialMediaLink,
      },
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response");
    }
    final status = (root["status"] as String?)?.toLowerCase();
    if (status != "success") {
      final msg = root["message"] as String? ?? "Request failed";
      throw ApiFailure(msg);
    }
    return const ApiResponse<void>();
  }

  @override
  Future<ApiResponse<InterviewPickerData>> getInterviewSlots() async {
    final response = await _networkService.get(
      ApiRoute.applicantInterviewSlots,
    );
    final root = response.data as Map<String, dynamic>;
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response");
    }
    return ApiResponse(data: InterviewPickerData.fromJson(data));
  }

  @override
  Future<ApiResponse<InterviewBookingConfirmation>>
  postApplicantInterviewBooking({required String slotUid}) async {
    final response = await _networkService.post(
      ApiRoute.applicantInterviewBookings,
      data: <String, dynamic>{"slot_uid": slotUid},
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response");
    }
    final status = (root["status"] as String?)?.toLowerCase();
    if (status != "success") {
      final msg = root["message"] as String? ?? "Request failed";
      throw ApiFailure(msg);
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response");
    }
    return ApiResponse(data: InterviewBookingConfirmation.fromJson(data));
  }

  @override
  Future<ApiResponse<ApplicantSchedulePayload>> getApplicantSchedule() async {
    final response = await _networkService.get(ApiRoute.applicantSchedule);
    final root = response.data as Map<String, dynamic>;
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response");
    }
    return ApiResponse(data: ApplicantSchedulePayload.fromJson(data));
  }

  @override
  Future<ApiResponse<CurrentInterviewBookingPayload>>
  getCurrentInterviewBooking() async {
    final response = await _networkService.get(
      ApiRoute.applicantInterviewBookingCurrent,
    );
    final root = response.data as Map<String, dynamic>;
    final status = (root["status"] as String?)?.toLowerCase();
    if (status != "success") {
      final msg = root["message"] as String? ?? "Request failed";
      throw ApiFailure(msg);
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response");
    }
    return ApiResponse(data: CurrentInterviewBookingPayload.fromJson(data));
  }
}

final applicationRepositoryProvider = Provider<ApplicationRepo>((ref) {
  return ApplicationRepoImpl(networkService: ref.read(networkServiceProvider));
});
