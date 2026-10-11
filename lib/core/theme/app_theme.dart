import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E90FF);
  static const primaryDark = Color(0xFF0066FF);
  static const accent = Color(0xFFFF6B00);
  static const success = Color(0xFF00C853);
  static const error = Color(0xFFFF1744);
  static const warning = Color(0xFFFFAB00);

  // 🔥 DEĞİŞKENLER (tema ile değişir)
  static Color background = const Color(0xFF000000);
  static Color surface = const Color(0xFF0A0A0A);
  static Color card = const Color(0xFF111111);
  static Color text = const Color(0xFFFFFFFF);
  static Color textSecondary = const Color(0xFFAAAAAA);

  static void setDark() {
    background = const Color(0xFF000000);
    surface = const Color(0xFF0A0A0A);
    card = const Color(0xFF111111);
    text = const Color(0xFFFFFFFF);
    textSecondary = const Color(0xFFAAAAAA);
  }

  static void setLight() {
    background = const Color(0xFFF5F5F5);
    surface = const Color(0xFFFFFFFF);
    card = const Color(0xFFE8E8E8);
    text = const Color(0xFF000000);
    textSecondary = const Color(0xFF666666);
  }
}

class AppTheme {
  static ThemeData buildDark(Color accent) {
    AppColors.setDark();
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: accent,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData buildLight(Color accent) {
    AppColors.setLight();
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: accent,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      useMaterial3: true,
    );
  }
}
