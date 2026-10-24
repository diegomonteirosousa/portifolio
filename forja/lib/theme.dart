import 'package:flutter/material.dart';

class AppColors {
  static const volt = Color(0xFFC6F432);
  static const bg = Color(0xFF0E0F11);
  static const surface = Color(0xFF17191C);
  static const card = Color(0xFF1F2226);
  static const cardHigh = Color(0xFF292D32);
  static const text = Color(0xFFF2F4F5);
  static const muted = Color(0xFF9AA1A9);
  static const fire = Color(0xFFFF7A45);
  static const water = Color(0xFF4FC3F7);
  static const danger = Color(0xFFFF5370);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.volt,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.volt,
    onPrimary: Colors.black,
    secondary: AppColors.fire,
    onSecondary: Colors.black,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.volt.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.volt,
        foregroundColor: Colors.black,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(64, 52),
        side: const BorderSide(color: AppColors.cardHigh, width: 1.5),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.volt,
      side: BorderSide.none,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.cardHigh,
      contentTextStyle: TextStyle(color: AppColors.text),
    ),
    dividerColor: AppColors.cardHigh,
  );
}
