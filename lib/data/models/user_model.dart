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
    );
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
    bool clearApplicationStatus = false,
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
        other.applicationStatus == applicationStatus;
  }

  @override
  int get hashCode => Object.hash(
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
  );

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, phoneNumber: $phoneNumber, isoCode: $isoCode, avatar: $avatar, isPhoneVerified: $isPhoneVerified, participationType: ${participationType.name}, emailVerifiedAt: $emailVerifiedAt, createdAt: $createdAt, updatedAt: $updatedAt, eligible: $eligible, applicationStatus: $applicationStatus)';
  }
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
