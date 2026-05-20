class PollOptionData {
  const PollOptionData({
    required this.uid,
    required this.title,
    required this.percentage,
    required this.progress,
    this.selected = false,
    required this.pollHasVoted,
  });

  final String uid;
  final String title;
  final int percentage;
  final double progress;
  final bool selected;
  final bool pollHasVoted;
}
