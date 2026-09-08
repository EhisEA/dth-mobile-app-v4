import "package:dth_v4/features/voting/models/voting_contestant.dart";

class VotingContestantPerformance {
  const VotingContestantPerformance({
    required this.title,
    required this.thumbnailUrl,
    this.uid = "",
    this.videoLink = "",
  });

  final String uid;
  final String title;
  final String thumbnailUrl;
  final String videoLink;

  factory VotingContestantPerformance.fromJson(Map<String, dynamic> json) {
    return VotingContestantPerformance(
      uid: json["uid"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      thumbnailUrl: json["video_thumbnail"]?.toString() ?? "",
      videoLink: json["video_link"]?.toString() ?? "",
    );
  }
}

class VotingContestantDetail {
  const VotingContestantDetail({
    required this.uid,
    required this.name,
    required this.code,
    required this.imageUrl,
    required this.isUpForEviction,
    required this.tagline,
    required this.biography,
    required this.performances,
    this.socials = "",
    this.isEvicted = false,
    this.isVotable = true,
    this.votingWeekContestantUid,
  });

  final String uid;
  final String name;
  final String code;
  final String imageUrl;
  final bool isUpForEviction;
  final String tagline;
  final String biography;
  final List<VotingContestantPerformance> performances;
  final String socials;
  final bool isEvicted;
  final bool isVotable;
  final String? votingWeekContestantUid;

  factory VotingContestantDetail.fromJson(Map<String, dynamic> json) {
    final rawPerformances = json["past_performances"];
    final performances = rawPerformances is List
        ? rawPerformances
              .whereType<Map>()
              .map(
                (e) => VotingContestantPerformance.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
        : const <VotingContestantPerformance>[];

    final rawWeekUid = json["voting_week_contestant_uid"]?.toString().trim();

    return VotingContestantDetail(
      uid: json["uid"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      code: json["user_id"]?.toString() ?? "",
      imageUrl: json["photo"]?.toString() ?? "",
      isUpForEviction: json["up_for_eviction"] == true,
      tagline: json["tagline"]?.toString() ?? "",
      biography: json["biography"]?.toString() ?? "",
      performances: performances,
      socials: json["socials"]?.toString() ?? "",
      isEvicted: json["evicted"] == true,
      isVotable: json["votable"] != false,
      votingWeekContestantUid:
          (rawWeekUid == null || rawWeekUid.isEmpty) ? null : rawWeekUid,
    );
  }

  /// Whether the detail screen may offer a vote. Defers to
  /// [VotingContestant.canCastVote] (cast uid present and not evicted) so the
  /// list card and this screen can never disagree, and additionally honours
  /// the detail-only `votable` flag.
  bool get canCastVote => isVotable && toContestant.canCastVote;

  VotingContestant get toContestant => VotingContestant(
    uid: uid,
    name: name,
    code: code,
    imageUrl: imageUrl,
    isUpForEviction: isUpForEviction,
    isEvicted: isEvicted,
    bio: biography.trim().isEmpty ? null : biography.trim(),
    votingWeekContestantUid: votingWeekContestantUid,
  );
}
