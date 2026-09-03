import "package:dth_v4/features/voting/models/voting_credit_info.dart";
import "package:dth_v4/features/voting/models/voting_credits.dart";
import "package:dth_v4/features/voting/models/voting_tutorial.dart";

class VotingWeekData {
  const VotingWeekData({
    required this.uid,
    required this.title,
    required this.endsAt,
    required this.credits,
    required this.voteValues,
    required this.tutorial,
    required this.creditInfo,
  });

  final String uid;
  final String title;
  final DateTime? endsAt;
  final VotingCredits credits;
  final List<int> voteValues;
  final VotingTutorial? tutorial;
  final VotingCreditInfo creditInfo;

  /// True for the [empty] sentinel returned when the response body is missing
  /// or malformed — lets callers distinguish "no data" from a real week so a
  /// transient bad response doesn't overwrite good state.
  bool get isEmpty => uid.isEmpty;

  factory VotingWeekData.fromJson(Map<String, dynamic> json) {
    final week = json["voting_week"];
    final weekMap = week is Map
        ? Map<String, dynamic>.from(week)
        : <String, dynamic>{};

    final userVoting = json["user_voting_data"];
    final userVotingMap = userVoting is Map
        ? Map<String, dynamic>.from(userVoting)
        : <String, dynamic>{};

    final credits = VotingCredits.fromUserVotingData(userVotingMap);

    final rawValues = userVotingMap["vote_values"];
    final voteValues = rawValues is List
        ? rawValues
              .map((e) {
                if (e is int) return e;
                if (e is num) return e.toInt();
                return int.tryParse(e.toString());
              })
              .whereType<int>()
              .toList(growable: false)
        : const <int>[];

    final tutorialRaw = json["tutorial"];
    final tutorial = tutorialRaw is Map
        ? VotingTutorial.fromJson(Map<String, dynamic>.from(tutorialRaw))
        : null;

    final creditInfoRaw = json["voting_credit_info"];
    final creditInfo = creditInfoRaw is Map
        ? VotingCreditInfo.fromJson(Map<String, dynamic>.from(creditInfoRaw))
        : VotingCreditInfo.fallback;

    return VotingWeekData(
      uid: weekMap["uid"]?.toString() ?? "",
      title: weekMap["title"]?.toString() ?? "",
      endsAt: DateTime.tryParse(weekMap["ends_at"]?.toString() ?? ""),
      credits: credits,
      voteValues: voteValues,
      tutorial: tutorial,
      creditInfo: creditInfo,
    );
  }

  static const empty = VotingWeekData(
    uid: "",
    title: "",
    endsAt: null,
    credits: VotingCredits(used: 0, total: 0),
    voteValues: [],
    tutorial: null,
    creditInfo: VotingCreditInfo.fallback,
  );
}
