import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// App theme data configuration
///
/// Defines the app light theme. This centralizes theme styling for consistency.
class AppThemeData {
  /// Light theme configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: AppFontFamily.primary,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: Colors.grey,
      error: Colors.red,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      displayMedium: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      displaySmall: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      titleMedium: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      titleSmall: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Color(0xFF595959),
      ),
      bodyMedium: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Color(0xFF595959),
      ),
      bodySmall: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Color(0xFF595959),
      ),
      labelLarge: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      labelMedium: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
      labelSmall: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Colors.black,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFF2F2F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFF2F2F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
      hintStyle: TextStyle(
        fontFamily: AppFontFamily.primary,
        color: Color(0xFF828282),
      ),
    ),
  );
}
