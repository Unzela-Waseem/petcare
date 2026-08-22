import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const cream = Color(0xFFFFF8EE);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF171512);
  static const muted = Color(0xFF7D7973);
  static const orange = Color(0xFFFFA83E);
  static const orangeDeep = Color(0xFFF58C24);
  static const peach = Color(0xFFF3C4AA);
  static const peachLight = Color(0xFFFFE8D9);
  static const lavender = Color(0xFFE4D5FF);
  static const yellow = Color(0xFFFFE9A8);
  static const mint = Color(0xFFCDEEDB);
  static const border = Color(0xFFF0ECE6);
  static const danger = Color(0xFFE34C4C);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 46,
          height: 1.08,
          letterSpacing: -2.2,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          height: 1.12,
          letterSpacing: -1.1,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.18,
          letterSpacing: -0.7,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.ink),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.orange,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
