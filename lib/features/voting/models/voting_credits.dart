class VotingCredits {
  const VotingCredits({
    required this.used,
    required this.total,
    required this.remaining,
  });

  final int used;
  final int total;

  /// Backend-provided `remaining_votes`.
  final int remaining;

  bool get hasCreditsRemaining => remaining > 0;

  String get label => "$remaining/$total votes";

  /// Header chip copy, e.g. `500 credits`.
  String get remainingLabel => "$remaining credits";

  VotingCredits copyWith({int? used, int? total, int? remaining}) {
    return VotingCredits(
      used: used ?? this.used,
      total: total ?? this.total,
      remaining: remaining ?? this.remaining,
    );
  }

  factory VotingCredits.fromUserVotingData(Map<String, dynamic> json) {
    return VotingCredits(
      used: _asInt(json["casted_votes"]),
      total: _asInt(json["total_votes_credit"]),
      remaining: _asInt(json["remaining_votes"]),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }
}
