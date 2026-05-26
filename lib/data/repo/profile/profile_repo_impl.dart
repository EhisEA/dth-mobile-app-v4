import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ProfileRepoImpl implements ProfileRepo {
  ProfileRepoImpl({
    required NetworkService networkService,
    required LocalCache localCache,
  }) : _networkService = networkService,
       _localCache = localCache;

  final NetworkService _networkService;
  final LocalCache _localCache;

  @override
  Future<ApiResponse<String>> sendPhoneOtp({
    required String phone,
    required String channel,
  }) async {
    final response = await _networkService.post(
      ApiRoute.profilePhoneSendOtp,
      data: {"phone": phone, "channel": channel},
    );
    final root = response.data as Map<String, dynamic>;
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      return const ApiResponse(data: null);
    }
    final sig = data["signature"] as String?;
    return ApiResponse(data: sig);
  }

  @override
  Future<ApiResponse<ProfilePhoneSubmitResult>> submitProfilePhone({
    required String isoCode,
    required String phone,
  }) async {
    final response = await _networkService.post(
      ApiRoute.profilePhone,
      data: {"iso_code": isoCode, "phone": phone},
    );
    final root = response.data as Map<String, dynamic>;
    return ApiResponse(data: ProfilePhoneSubmitResult.fromResponseRoot(root));
  }

  @override
  Future<ApiResponse<void>> verifyPhoneOtp({
    required String token,
    required String signature,
    String? deviceName,
  }) async {
    final payload = <String, dynamic>{"token": token, "signature": signature};
    final dn = deviceName?.trim();
    if (dn != null && dn.isNotEmpty) {
      payload["device_name"] = dn;
    }
    await _networkService.post(ApiRoute.profilePhoneVerifyOtp, data: payload);
    return const ApiResponse();
  }

  @override
  Future<ApiResponse<UserModel>> updateProfile({
    String? fullName,
    String? phone,
    String? isoCode,
    String? avatarFilePath,
  }) async {
    final fields = <String, dynamic>{};
    if (fullName != null) fields["full_name"] = fullName;
    if (phone != null) fields["phone"] = phone;
    if (isoCode != null) fields["iso_code"] = isoCode;

    final Map<String, dynamic>? file =
        (avatarFilePath != null && avatarFilePath.isNotEmpty)
        ? {"avatar": avatarFilePath}
        : null;

    final response = await _networkService.putFormData(
      ApiRoute.profileUpdate,
      data: fields.isEmpty ? null : fields,
      file: file,
    );
    final data =
        (response.data as Map<String, dynamic>)["data"]["user"]
            as Map<String, dynamic>;
    final result = UserModel.fromJson(data);
    await _localCache.saveUserData(result.toJson());
    return ApiResponse(data: result);
  }

  @override
  Future<ApiResponse<String>> requestAccountDeletion({
    String? deviceName,
  }) async {
    final Object? body;
    final trimmed = deviceName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      body = {"device_name": trimmed};
    } else {
      body = null;
    }
    final response = await _networkService.get(
      ApiRoute.profileDeleteAccount,
      data: body,
    );
    final root = response.data as Map<String, dynamic>;
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      return const ApiResponse(data: null);
    }
    final sig = data["signature"] as String?;
    return ApiResponse(data: sig);
  }

  @override
  Future<ApiResponse<String?>> confirmAccountDeletion({
    required String token,
    required String signature,
    String? deviceName,
    String? fcmToken,
  }) async {
    final payload = <String, dynamic>{"token": token, "signature": signature};
    final dn = deviceName?.trim();
    if (dn != null && dn.isNotEmpty) {
      payload["device_name"] = dn;
    }
    final ft = fcmToken?.trim();
    if (ft != null && ft.isNotEmpty) {
      payload["fcm_token"] = ft;
    }
    final response = await _networkService.post(
      ApiRoute.profileDeleteAccount,
      data: payload,
    );
    final root = response.data as Map<String, dynamic>;
    final message = root["message"] as String?;
    return ApiResponse(data: message);
  }
}

final profileRepositoryProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepoImpl(
    networkService: ref.read(networkServiceProvider),
    localCache: ref.read(localCacheProvider),
  );
});
