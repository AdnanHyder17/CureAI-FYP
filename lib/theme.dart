// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF33658A);      // Deep Blue - Primary color
  static const Color secondary = Color(0xFF55DDE0);    // Light Blue - Accent color
  static const Color dark = Color(0xFF2F4858);         // Dark text & elements
  static const Color light = Color(0xFFF0F4F8);        // Light background
  static const Color white = Colors.white;             // Pure white
  static const Color gray = Color(0xFFB0BEC5);         // Soft gray for disabled elements

  // Additional theme colors
  static const Color success = Color(0xFF4CAF50);      // Success (Green)
  static const Color warning = Color(0xFFFFC107);      // Warning (Yellow)
  static const Color error = Color(0xFFE53935);        // Error (Red)
  static const Color surface = Color(0xFFFFFFFF);     // Surface color for cards
  static const Color onSurface = Color(0xFF2F4858);   // Text color on surface
  static const Color onPrimary = Color(0xFFFFFFFF);    // Text color on primary
  static const Color onSecondary = Color(0xFF2F4858);  // Text color on secondary
}

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    background: AppColors.light,
    onPrimary: AppColors.onPrimary,
    onSecondary: AppColors.onSecondary,
    onSurface: AppColors.onSurface,
    onBackground: AppColors.dark,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.light,
  textTheme: TextTheme(
    displayLarge: TextStyle(color: AppColors.dark, fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: AppColors.dark, fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: AppColors.dark, fontSize: 24, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: AppColors.dark, fontSize: 22, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: AppColors.dark, fontSize: 20, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: AppColors.dark, fontSize: 18, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(color: AppColors.dark, fontSize: 16),
    bodySmall: TextStyle(color: AppColors.dark, fontSize: 14),
    labelLarge: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
    labelSmall: TextStyle(color: AppColors.gray, fontSize: 12),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: AppColors.primary,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      elevation: 2,
      shadowColor: AppColors.dark.withOpacity(0.2),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gray)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.gray)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary, width: 2)),
    labelStyle: TextStyle(color: AppColors.dark),
    hintStyle: TextStyle(color: AppColors.gray),
  ),
  iconTheme: IconThemeData(color: AppColors.dark),
  cardTheme: CardTheme(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.all(8),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
  dividerTheme: DividerThemeData(
    color: AppColors.gray.withOpacity(0.5),
    thickness: 1,
    space: 16,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 4,
  ),
);