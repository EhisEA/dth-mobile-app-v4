/// Primary UI typeface. Must match `fonts` → `family` in [pubspec.yaml].
abstract final class AppFontFamily {
  static const String primary = 'Hanken Grotesk';
  static const String secondary = 'Matter';
  static const String cascadiaMono = 'Cascadia Mono';
  static const String hanson = 'Hanson';
  static const String athleticsSans = 'Athletics Sans';
  static const String bangers = 'Bangers';
  static const String shantellSans = 'Shantell Sans';

  /// Bundled emoji typeface used as a glyph fallback so emoji render the same
  /// on every device, instead of relying on each OS's (version-dependent)
  /// emoji font. Applied to every [AppTextStyle]. Must match the `family` under
  /// `flutter.fonts` in [pubspec.yaml].
  static const String emoji = 'Noto Color Emoji';

  /// Fallback chain for text styles: try the primary glyph, then [emoji].
  static const List<String> fallback = [emoji];
}
