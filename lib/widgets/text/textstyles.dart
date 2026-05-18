import "package:dth_v4/core/constants/typography.dart";
import "package:flutter/material.dart";

/// Typography for [AppFontFamily.primary] (Hanken Grotesk). Names match the
/// font files / weights declared under `flutter.fonts` in [pubspec.yaml].
class AppTextStyle {
  static const double _ls = -0.2;

  /// Weight 200 — `HankenGrotesk-ExtraLight.ttf` in pubspec.
  static const TextStyle extraLight = TextStyle(
    fontFamily: AppFontFamily.primary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w200,
  );

  /// Weight 300 — `HankenGrotesk-Light.ttf`.
  static const TextStyle light = TextStyle(
    fontFamily: AppFontFamily.primary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w300,
  );

  /// Weight 400 — `HankenGrotesk-Regular.ttf`.
  static const TextStyle regular = TextStyle(
    fontFamily: AppFontFamily.primary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w400,
  );

  /// Weight 500 — `HankenGrotesk-Medium.ttf`.
  static const TextStyle medium = TextStyle(
    fontFamily: AppFontFamily.primary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w500,
  );

  /// Weight 600 — `HankenGrotesk-SemiBold.ttf`.
  static const TextStyle semiBold = TextStyle(
    fontFamily: AppFontFamily.primary,
    fontSize: 18,
    letterSpacing: _ls,
    fontWeight: FontWeight.w600,
  );

  /// Weight 700 — `HankenGrotesk-Bold.ttf`.
  static const TextStyle bold = TextStyle(
    fontFamily: AppFontFamily.primary,
    fontSize: 22,
    letterSpacing: _ls,
    fontWeight: FontWeight.w700,
  );

  /// Weight 900 — `HankenGrotesk-Black.ttf`.
  static const TextStyle black = TextStyle(
    fontFamily: AppFontFamily.primary,
    fontSize: 24,
    letterSpacing: _ls,
    fontWeight: FontWeight.w900,
  );

  /// Weight 300 — `Matter-Light.ttf`.
  static const TextStyle matterLight = TextStyle(
    fontFamily: AppFontFamily.secondary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w300,
  );

  /// Weight 400 — `Matter-Regular.ttf`.
  static const TextStyle matterRegular = TextStyle(
    fontFamily: AppFontFamily.secondary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w400,
  );

  /// Weight 500 — `Matter-Medium.ttf`.
  static const TextStyle matterMedium = TextStyle(
    fontFamily: AppFontFamily.secondary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w500,
  );

  /// Weight 600 — `Matter-SemiBold.ttf`.
  static const TextStyle matterSemiBold = TextStyle(
    fontFamily: AppFontFamily.secondary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w600,
  );

  /// Weight 700 — `Matter-Bold.ttf`.
  static const TextStyle matterBold = TextStyle(
    fontFamily: AppFontFamily.secondary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w700,
  );

  /// Weight 800 — `Matter-Heavy.ttf`.
  static const TextStyle matterHeavy = TextStyle(
    fontFamily: AppFontFamily.secondary,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w800,
  );

  /// Weight 200 — `CascadiaMono-ExtraLight.ttf`.
  static const TextStyle cascadiaMonoExtraLight = TextStyle(
    fontFamily: AppFontFamily.cascadiaMono,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w200,
  );

  /// Weight 300 — `CascadiaMono-Light.ttf`.
  static const TextStyle cascadiaMonoLight = TextStyle(
    fontFamily: AppFontFamily.cascadiaMono,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w300,
  );

  /// Weight 400 — `CascadiaMono-Regular.ttf`.
  static const TextStyle cascadiaMonoRegular = TextStyle(
    fontFamily: AppFontFamily.cascadiaMono,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w400,
  );

  /// Weight 500 — `CascadiaMono-Medium.ttf`.
  static const TextStyle cascadiaMonoMedium = TextStyle(
    fontFamily: AppFontFamily.cascadiaMono,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w500,
  );

  /// Weight 600 — `CascadiaMono-SemiBold.ttf`.
  static const TextStyle cascadiaMonoSemiBold = TextStyle(
    fontFamily: AppFontFamily.cascadiaMono,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w600,
  );

  /// Weight 700 — `CascadiaMono-Bold.ttf`.
  static const TextStyle cascadiaMonoBold = TextStyle(
    fontFamily: AppFontFamily.cascadiaMono,
    fontSize: 16,
    letterSpacing: _ls,
    fontWeight: FontWeight.w700,
  );
}
