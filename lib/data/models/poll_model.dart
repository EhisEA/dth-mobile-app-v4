int _pollAsInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final normalized = value.trim().replaceAll(",", "");
    if (normalized.isEmpty) return 0;
    final asDouble = double.tryParse(normalized);
    if (asDouble != null) return asDouble.round();
    return int.tryParse(normalized) ?? 0;
  }
  final parsed = double.tryParse(value.toString().replaceAll(",", ""));
  if (parsed != null) return parsed.round();
  return 0;
}

bool _pollAsBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == "true" || normalized == "1" || normalized == "yes";
  }
  return false;
}

String _pollAsString(dynamic value) {
  if (value == null) return "";
  return value.toString().trim();
}

class PollOptionModel {
  const PollOptionModel({
    required this.uid,
    required this.name,
    required this.votesCount,
    required this.percentage,
  });

  final String uid;
  final String name;
  final int votesCount;
  final int percentage;

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      uid: _pollAsString(json["uid"]),
      name: _pollAsString(json["name"]),
      votesCount: _pollAsInt(json["votes_count"]),
      percentage: _pollAsInt(json["percentage"]),
    );
  }
}

class PollModel {
  const PollModel({
    required this.uid,
    required this.title,
    required this.subtitle,
    required this.question,
    required this.description,
    required this.totalVotes,
    required this.totalVotesDescription,
    required this.status,
    required this.hasEnded,
    required this.timeLeft,
    required this.endsAt,
    required this.hasVoted,
    required this.votedOptionUid,
    required this.options,
  });

  final String uid;
  final String title;
  final String subtitle;
  final String question;
  final String description;
  final int totalVotes;
  final String totalVotesDescription;
  final String status;
  final bool hasEnded;
  final String timeLeft;
  final String endsAt;
  final bool hasVoted;
  final String? votedOptionUid;
  final List<PollOptionModel> options;

  /// Single source of truth for "is this poll closed to new votes". Treats the
  /// boolean flag and the string status as equivalent so a backend that updates
  /// one but not the other can't accidentally leave the UI in a votable state.
  bool get isClosed => hasEnded || status.trim().toLowerCase() == "ended";

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json["options"];
    final options = optionsRaw is List<dynamic>
        ? optionsRaw
              .whereType<Map>()
              .map(
                (e) => PollOptionModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <PollOptionModel>[];

    final votedUidRaw = _pollAsString(json["voted_option_uid"]);
    return PollModel(
      uid: _pollAsString(json["uid"]),
      title: _pollAsString(json["title"]),
      subtitle: _pollAsString(json["subtitle"]),
      question: _pollAsString(json["question"]),
      description: _pollAsString(json["description"]),
      totalVotes: _pollAsInt(json["total_votes"]),
      totalVotesDescription: _pollAsString(json["total_votes_description"]),
      status: _pollAsString(json["status"]),
      hasEnded: _pollAsBool(json["has_ended"]),
      timeLeft: _pollAsString(json["time_left"]),
      endsAt: _pollAsString(json["ends_at"]),
      hasVoted: _pollAsBool(json["has_voted"]),
      votedOptionUid: votedUidRaw.isEmpty ? null : votedUidRaw,
      options: options,
    );
  }
}

class PollVoteRequest {
  const PollVoteRequest({required this.optionUid});

  final String optionUid;

  Map<String, dynamic> toJson() => {"option_uid": optionUid};
}
