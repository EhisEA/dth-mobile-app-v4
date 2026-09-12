import "package:dth_v4/data/data.dart";
import "package:flutter_utils/flutter_utils.dart";

abstract class ProfileRepo {
  Future<ApiResponse<String>> sendPhoneOtp({
    required String phone,
    required String channel,
  });

  Future<ApiResponse<ProfilePhoneSubmitResult>> submitProfilePhone({
    required String isoCode,
    required String phone,
  });

  Future<ApiResponse<void>> verifyPhoneOtp({
    required String token,
    required String signature,
    String? deviceName,
  });

  Future<ApiResponse<UserModel>> updateProfile({
    String? fullName,
    String? phone,
    String? isoCode,
    String? avatarFilePath,
  });

  Future<ApiResponse<String>> requestAccountDeletion({String? deviceName});

  Future<ApiResponse<String?>> confirmAccountDeletion({
    required String token,
    required String signature,
    String? deviceName,
    String? fcmToken,
  });

  Future<ApiResponse<List<BankAccount>>> getBankAccounts();

  Future<ApiResponse<List<BankInstitution>>> getBanks({String? search});

  Future<ApiResponse<String>> resolveBankAccount({
    required String bankUid,
    required String accountNumber,
  });

  Future<ApiResponse<BankAccount>> addBankAccount({
    required String bankUid,
    required String accountNumber,
    required String accountName,
  });

  Future<ApiResponse<BankAccountDeleteOtpSession>> requestBankAccountDeleteOtp({
    required String bankAccountUid,
  });

  Future<ApiResponse<void>> deleteBankAccount({
    required String bankAccountUid,
    required String token,
    required String signature,
  });

  Future<ApiResponse<Withdrawal>> createWithdrawal({
    required num amount,
    required String bankAccountUid,
  });
}
