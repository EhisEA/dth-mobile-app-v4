class VotingCredits {
  const VotingCredits({required this.used, required this.total});

  final int used;
  final int total;

  int get remaining => (total - used).clamp(0, total);

  bool get hasCreditsRemaining => remaining > 0;

  String get label => "$remaining/$total votes";

  VotingCredits copyWith({int? used, int? total}) {
    return VotingCredits(used: used ?? this.used, total: total ?? this.total);
  }

  factory VotingCredits.fromUserVotingData(Map<String, dynamic> json) {
    final total = _asInt(json["total_votes_credit"]);
    final used = _asInt(json["casted_votes"]);
    return VotingCredits(used: used, total: total);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }
}
