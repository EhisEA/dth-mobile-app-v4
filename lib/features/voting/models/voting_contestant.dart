class VotingContestant {
  const VotingContestant({
    required this.uid,
    required this.name,
    required this.code,
    required this.imageUrl,
    required this.isUpForEviction,
    this.isEvicted = false,
    this.bio,
    this.votingWeekContestantUid,
  });

  final String uid;
  final String name;
  final String code;
  final String imageUrl;
  final bool isUpForEviction;
  final bool isEvicted;
  final String? bio;
  final String? votingWeekContestantUid;

  bool get canCastVote {
    final castUid = votingWeekContestantUid?.trim() ?? "";
    return castUid.isNotEmpty && !isEvicted;
  }

  factory VotingContestant.fromJson(Map<String, dynamic> json) {
    final rawBio = json["bio"]?.toString().trim();
    final rawWeekUid = json["voting_week_contestant_uid"]?.toString().trim();
    return VotingContestant(
      uid: json["uid"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      code: json["user_id"]?.toString() ?? "",
      imageUrl: json["photo"]?.toString() ?? "",
      isUpForEviction: json["up_for_eviction"] == true,
      isEvicted: json["evicted"] == true,
      bio: (rawBio == null || rawBio.isEmpty) ? null : rawBio,
      votingWeekContestantUid:
          (rawWeekUid == null || rawWeekUid.isEmpty) ? null : rawWeekUid,
    );
  }
}
