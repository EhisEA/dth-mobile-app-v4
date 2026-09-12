import "package:dth_v4/data/models/voting_credit_breakdown.dart";

class UserModel {
  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.isoCode,
    required this.avatar,
    required this.isPhoneVerified,
    required this.participationType,
    required this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.eligible = false,
    this.applicationStatus,
    this.isSubscribed = false,
    this.votingCredit = 0,
    this.votingCreditBreakdown,
    this.walletBalance,
    this.pendingWithdrawalRequest,
    this.leaderboardEligible = false,
    this.withdrawalLimit,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String isoCode;
  final String avatar;
  final bool isPhoneVerified;
  final ParticipationType participationType;
  final String emailVerifiedAt;
  final String createdAt;
  final String updatedAt;

  /// When true, the applicant dashboard entry may be shown on profile.
  final bool eligible;

  /// Profile `application_status` (e.g. variant + label from GET /profile).
  final ApplicationStatus? applicationStatus;

  /// Whether the user has an active subscription (`is_subscribed` from GET /profile).
  final bool isSubscribed;

  /// Available voting credits from GET /profile (`voting_credit`).
  final int votingCredit;

  /// Credit breakdown from GET /profile (`voting_credit_breakdown`).
  final VotingCreditBreakdown? votingCreditBreakdown;

  /// Wallet balance from GET /profile (`wallet_balance` on user).
  final WalletBalance? walletBalance;

  /// In-flight withdrawal from GET /profile (`pending_withdrawal_request`).
  final PendingWithdrawalRequest? pendingWithdrawalRequest;

  /// When true with the leaderboard module, show leaderboard + wallet/bank UI.
  final bool leaderboardEligible;

  /// Min/max withdraw amounts from GET /profile (`withdrawal_limit`).
  final WithdrawalLimit? withdrawalLimit;

  /// Profile chip label, e.g. `120 credits`.
  String get votingCreditLabel => "$votingCredit credits";

  /// Formatted wallet balance for profile pill, e.g. `₦0`.
  String get walletBalanceLabel =>
      walletBalance?.formattedLabel ?? const WalletBalance().formattedLabel;

  /// Parsed [participationType.name] as [ParticipationRole].
  ParticipationRole get participationRole =>
      ParticipationRole.fromName(participationType.name);

  bool get isUserRole => participationRole == ParticipationRole.user;
  bool get isApplicantRole => participationRole == ParticipationRole.applicant;
  bool get isContestantRole =>
      participationRole == ParticipationRole.contestant;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: _stringField(json['uid'] ?? json['id']),
      fullName: _stringField(json['full_name']),
      email: _stringField(json['email']),
      phoneNumber: _stringField(json['phone']),
      isoCode: _stringField(json['iso_code']),
      avatar: _stringField(json['avatar']),
      isPhoneVerified: _boolField(json['is_phone_verified']),
      participationType: ParticipationType.fromJson(json['participation_type']),
      emailVerifiedAt: _stringField(json['email_verified_at']),
      createdAt: _stringField(json['created_at']),
      updatedAt: _stringField(json['updated_at']),
      eligible: _boolField(json['eligible']),
      applicationStatus: _parseApplicationStatus(json['application_status']),
      isSubscribed: _boolField(json['is_subscribed']),
      votingCredit: _asInt(json['voting_credit']),
      votingCreditBreakdown: json['voting_credit_breakdown'] == null
          ? null
          : VotingCreditBreakdown.fromJson(json['voting_credit_breakdown']),
      walletBalance: WalletBalance.tryParse(json['wallet_balance']),
      pendingWithdrawalRequest: PendingWithdrawalRequest.tryParse(
        json['pending_withdrawal_request'],
      ),
      leaderboardEligible: _boolField(json['leaderboard_eligible']),
      withdrawalLimit: WithdrawalLimit.tryParse(json['withdrawal_limit']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static ApplicationStatus? _parseApplicationStatus(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final status = ApplicationStatus.fromJson(json);
    return status.isEmpty ? null : status;
  }

  static String _stringField(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static bool _boolField(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'phone': phoneNumber,
      'iso_code': isoCode,
      'avatar': avatar,
      'is_phone_verified': isPhoneVerified,
      'participation_type': participationType.toJson(),
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'eligible': eligible,
      'is_subscribed': isSubscribed,
      'voting_credit': votingCredit,
      if (votingCreditBreakdown != null)
        'voting_credit_breakdown': votingCreditBreakdown!.toJson(),
      if (walletBalance != null) 'wallet_balance': walletBalance!.toJson(),
      if (pendingWithdrawalRequest != null)
        'pending_withdrawal_request': pendingWithdrawalRequest!.toJson(),
      'leaderboard_eligible': leaderboardEligible,
      if (withdrawalLimit != null)
        'withdrawal_limit': withdrawalLimit!.toJson(),
      if (applicationStatus != null)
        'application_status': applicationStatus!.toJson(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? isoCode,
    String? avatar,
    bool? isPhoneVerified,
    ParticipationType? participationType,
    String? emailVerifiedAt,
    String? createdAt,
    String? updatedAt,
    bool? eligible,
    ApplicationStatus? applicationStatus,
    bool? isSubscribed,
    int? votingCredit,
    VotingCreditBreakdown? votingCreditBreakdown,
    WalletBalance? walletBalance,
    PendingWithdrawalRequest? pendingWithdrawalRequest,
    bool? leaderboardEligible,
    WithdrawalLimit? withdrawalLimit,
    bool clearVotingCreditBreakdown = false,
    bool clearApplicationStatus = false,
    bool clearWalletBalance = false,
    bool clearPendingWithdrawalRequest = false,
    bool clearWithdrawalLimit = false,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isoCode: isoCode ?? this.isoCode,
      avatar: avatar ?? this.avatar,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      participationType: participationType ?? this.participationType,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      eligible: eligible ?? this.eligible,
      applicationStatus: clearApplicationStatus
          ? null
          : (applicationStatus ?? this.applicationStatus),
      isSubscribed: isSubscribed ?? this.isSubscribed,
      votingCredit: votingCredit ?? this.votingCredit,
      votingCreditBreakdown: clearVotingCreditBreakdown
          ? null
          : (votingCreditBreakdown ?? this.votingCreditBreakdown),
      walletBalance: clearWalletBalance
          ? null
          : (walletBalance ?? this.walletBalance),
      pendingWithdrawalRequest: clearPendingWithdrawalRequest
          ? null
          : (pendingWithdrawalRequest ?? this.pendingWithdrawalRequest),
      leaderboardEligible: leaderboardEligible ?? this.leaderboardEligible,
      withdrawalLimit: clearWithdrawalLimit
          ? null
          : (withdrawalLimit ?? this.withdrawalLimit),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.fullName == fullName &&
        other.phoneNumber == phoneNumber &&
        other.isoCode == isoCode &&
        other.avatar == avatar &&
        other.isPhoneVerified == isPhoneVerified &&
        other.participationType.name == participationType.name &&
        other.participationType.id == participationType.id &&
        other.emailVerifiedAt == emailVerifiedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.eligible == eligible &&
        other.applicationStatus == applicationStatus &&
        other.isSubscribed == isSubscribed &&
        other.votingCredit == votingCredit &&
        other.votingCreditBreakdown == votingCreditBreakdown &&
        other.walletBalance == walletBalance &&
        other.pendingWithdrawalRequest == pendingWithdrawalRequest &&
        other.leaderboardEligible == leaderboardEligible &&
        other.withdrawalLimit == withdrawalLimit;
  }

  @override
  int get hashCode => Object.hashAll([
    uid,
    email,
    fullName,
    phoneNumber,
    isoCode,
    avatar,
    isPhoneVerified,
    participationType.name,
    participationType.id,
    emailVerifiedAt,
    createdAt,
    updatedAt,
    eligible,
    applicationStatus,
    isSubscribed,
    votingCredit,
    votingCreditBreakdown,
    walletBalance,
    pendingWithdrawalRequest,
    leaderboardEligible,
    withdrawalLimit,
  ]);

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, phoneNumber: $phoneNumber, isoCode: $isoCode, avatar: $avatar, isPhoneVerified: $isPhoneVerified, participationType: ${participationType.name}, emailVerifiedAt: $emailVerifiedAt, createdAt: $createdAt, updatedAt: $updatedAt, eligible: $eligible, applicationStatus: $applicationStatus, isSubscribed: $isSubscribed, votingCredit: $votingCredit, votingCreditBreakdown: $votingCreditBreakdown, walletBalance: $walletBalance, pendingWithdrawalRequest: $pendingWithdrawalRequest, leaderboardEligible: $leaderboardEligible, withdrawalLimit: $withdrawalLimit)';
  }
}

/// `wallet_balance` on profile user payload.
class WalletBalance {
  const WalletBalance({this.currency = "NGN", this.amount = "0"});

  final String currency;
  final String amount;

  String get currencySymbol {
    final code = currency.trim().toUpperCase();
    if (code == "NGN" || code.isEmpty) return "₦";
    if (code == "USD") return "\$";
    return code;
  }

  /// e.g. `₦0`, `₦1,330.50` — amount is shown as received from the API.
  String get formattedLabel => "$currencySymbol$amount";

  static WalletBalance? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return WalletBalance.fromJson(json);
  }

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    final currency = UserModel._stringField(json["currency"]);
    return WalletBalance(
      currency: currency.isEmpty ? "NGN" : currency,
      amount: _amountField(json["amount"]),
    );
  }

  /// Accepts string, num, or other — always stored as string.
  static String _amountField(Object? value) {
    if (value == null) return "0";
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? "0" : trimmed;
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() => {"currency": currency, "amount": amount};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletBalance &&
        other.currency == currency &&
        other.amount == amount;
  }

  @override
  int get hashCode => Object.hash(currency, amount);

  @override
  String toString() => "WalletBalance(currency: $currency, amount: $amount)";
}

/// `withdrawal_limit` on profile user payload.
class WithdrawalLimit {
  const WithdrawalLimit({required this.minimum, required this.maximum});

  final int minimum;
  final int maximum;

  static WithdrawalLimit? tryParse(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final min = UserModel._asInt(map["minimum"]);
    final max = UserModel._asInt(map["maximum"]);
    if (min <= 0 && max <= 0) return null;
    return WithdrawalLimit(
      minimum: min > 0 ? min : 1,
      maximum: max > 0 ? max : min,
    );
  }

  Map<String, dynamic> toJson() => {"minimum": minimum, "maximum": maximum};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WithdrawalLimit &&
        other.minimum == minimum &&
        other.maximum == maximum;
  }

  @override
  int get hashCode => Object.hash(minimum, maximum);

  @override
  String toString() => "WithdrawalLimit(minimum: $minimum, maximum: $maximum)";
}

/// `pending_withdrawal_request` on profile user payload.
class PendingWithdrawalRequest {
  const PendingWithdrawalRequest({required this.amount});

  final WalletBalance amount;

  String get formattedLabel => amount.formattedLabel;

  static PendingWithdrawalRequest? tryParse(Object? json) {
    if (json == null) return null;
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    // Prefer nested amount object; otherwise treat this map as wallet-like.
    final amountRaw = map["amount"];
    final WalletBalance? balance;
    if (amountRaw is Map) {
      balance = WalletBalance.tryParse(Map<String, dynamic>.from(amountRaw));
    } else {
      balance = WalletBalance.tryParse(map);
    }
    if (balance == null) return null;
    return PendingWithdrawalRequest(amount: balance);
  }

  Map<String, dynamic> toJson() => {
    "currency": amount.currency,
    "amount": amount.amount,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingWithdrawalRequest && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => "PendingWithdrawalRequest(amount: $amount)";
}

/// `application_status` on profile user payload.
class ApplicationStatus {
  const ApplicationStatus({required this.variant, required this.label});

  final String variant;
  final String label;

  bool get isEmpty => label.trim().isEmpty;

  factory ApplicationStatus.fromJson(Map<String, dynamic> json) {
    return ApplicationStatus(
      variant: UserModel._stringField(json['variant']),
      label: UserModel._stringField(json['label']),
    );
  }

  Map<String, dynamic> toJson() => {'variant': variant, 'label': label};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApplicationStatus &&
        other.variant == variant &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(variant, label);

  @override
  String toString() => 'ApplicationStatus(variant: $variant, label: $label)';
}

/// API values for [ParticipationType.name] on `GET /auth/user`.
enum ParticipationRole {
  user,
  applicant,
  contestant,
  unknown;

  static ParticipationRole fromName(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'user':
        return ParticipationRole.user;
      case 'applicant':
        return ParticipationRole.applicant;
      case 'contestant':
        return ParticipationRole.contestant;
      default:
        return ParticipationRole.unknown;
    }
  }
}

class ParticipationType {
  const ParticipationType({required this.name, this.id});

  final String name;
  final String? id;

  factory ParticipationType.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const ParticipationType(name: '');
    }
    final m = json;
    return ParticipationType(
      name: _stringField(m['name']),
      id: m['id'] == null ? null : _stringField(m['id']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'id': id};

  static String _stringField(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
