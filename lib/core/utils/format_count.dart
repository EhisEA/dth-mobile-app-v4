/// Compact integer formatter for like / comment / view counts.
///
/// Examples: `13000 → "13K"`, `16100 → "16.1K"`, `1200000 → "1.2M"`,
/// `3000000000 → "3B"`. Values below 1000 render unchanged.
String formatCount(int n) {
  if (n < 0) return "$n";
  String fmt(double v, String suffix) {
    final s = v.toStringAsFixed(1);
    final trimmed = s.endsWith(".0") ? s.substring(0, s.length - 2) : s;
    return "$trimmed$suffix";
  }

  if (n >= 1000000000) return fmt(n / 1000000000, "B");
  if (n >= 1000000) return fmt(n / 1000000, "M");
  if (n >= 1000) return fmt(n / 1000, "K");
  return "$n";
}
