/// Request body for `POST /application`.
class ApplicationSubmitRequest {
  const ApplicationSubmitRequest({
    required this.fullName,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    required this.isoCode,
    required this.phone,
    required this.residentialAddress,
    required this.stateOfResidence,
    required this.stateOfOrigin,
    required this.city,
    required this.lga,
    required this.nearestCampus,
    required this.stageName,
    required this.talentCategoryId,
    required this.description,
    required this.modeOfPresentation,
    required this.sizeOfCrew,
    required this.nameOfParticipants,
    required this.videoLink,
    required this.socialMediaLink,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.isFinalStep,
    required this.includeBankDetails,
  });

  final String fullName;
  final String email;
  final String gender;
  final String dateOfBirth;
  final String isoCode;
  final String phone;
  final String residentialAddress;
  final String stateOfResidence;
  final String stateOfOrigin;
  final String city;
  final String lga;
  final String nearestCampus;
  final String stageName;
  final int talentCategoryId;
  final String description;
  final String modeOfPresentation;
  final String sizeOfCrew;
  final List<String> nameOfParticipants;
  final String videoLink;
  final String socialMediaLink;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final bool isFinalStep;

  /// When false (API `collect_bank_details` is false), bank fields are omitted
  /// from [toJson] so the server does not validate empty bank strings.
  final bool includeBankDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "full_name": fullName,
      "email": email,
      "gender": gender,
      "date_of_birth": dateOfBirth,
      "iso_code": isoCode,
      "phone": phone,
      "residential_address": residentialAddress,
      "state_of_residence": stateOfResidence,
      "state_of_origin": stateOfOrigin,
      "city": city,
      "lga": lga,
      "nearest_campus": nearestCampus,
      "stage_name": stageName,
      "talent_category_id": talentCategoryId,
      "description": description,
      "mode_of_presentation": modeOfPresentation,
      "size_of_crew": sizeOfCrew,
      "name_of_participants": nameOfParticipants,
      "video_link": videoLink,
      "social_media_link": socialMediaLink,
      "is_final_step": isFinalStep,
    };
    if (includeBankDetails) {
      map["bank_name"] = bankName;
      map["account_name"] = accountName;
      map["account_number"] = accountNumber;
    }
    return map;
  }
}
