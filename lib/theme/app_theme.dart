// lib/theme/app_theme.dart
//
// Titik pusat identitas visual baru aplikasi. File ini TIDAK mengubah tata
// letak (layout) satu pun halaman — ia hanya menyediakan gradasi, radius,
// shadow, dan ThemeData terpusat yang dipakai ulang oleh setiap halaman
// supaya tampil konsisten, modern, dan "mahal".
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double pill = 999;
}

class AppGradients {
  AppGradients._();

  /// Gradasi utama — tombol primer & elemen aksi utama.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand700, AppColors.brand900],
  );

  /// Gradasi tombol "Setuju" — sedikit lebih hidup dari tombol primer.
  static const LinearGradient approve = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand500, AppColors.brand700],
  );

  /// Gradasi header/app bar besar (mis. kartu identitas pengguna).
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand900, AppColors.brand700],
  );

  /// Motif "cincin" tanda tangan emas→hijau — dipakai di setiap avatar,
  /// logo, dan bingkai foto sebagai isyarat "cap resmi".
  static const SweepGradient seal = SweepGradient(
    colors: [
      AppColors.gold600,
      AppColors.gold600,
      AppColors.brand500,
      AppColors.gold600,
    ],
    stops: [0, 0.08, 0.5, 1],
    transform: GradientRotation(-0.7), // ~ -40deg
  );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.brand900.withOpacity(0.28),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.ink.withOpacity(0.06),
      blurRadius: 14,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> button(Color tint) => [
        BoxShadow(
          color: tint.withOpacity(0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Membangun [ThemeData] utuh untuk `MaterialApp`. Dipanggil sekali dari
/// `main.dart`; setiap halaman otomatis mewarisi warna, radius, dan jenis
/// huruf yang konsisten tanpa perlu mengubah struktur widget-nya.
ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand900,
    primary: AppColors.brand900,
    secondary: AppColors.gold600,
    surface: AppColors.surface,
    error: AppColors.rejectedFg,
  );

  return base.copyWith(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    splashFactory: InkRipple.splashFactory,

    textTheme: base.textTheme.apply(
      fontFamily: AppText.body,
      bodyColor: AppColors.ink,
      displayColor: AppColors.brand900,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.brand900,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: AppText.bodyStyle(
        size: 16,
        weight: FontWeight.w700,
        color: AppColors.brand900,
      ),
      iconTheme: const IconThemeData(color: AppColors.brand900),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 24,
    ),

    iconTheme: const IconThemeData(color: AppColors.brand700),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: AppText.bodyStyle(
        size: 13.5,
        weight: FontWeight.w500,
        color: AppColors.inkFaint,
      ),
      floatingLabelStyle: AppText.bodyStyle(
        size: 12.5,
        weight: FontWeight.w700,
        color: AppColors.brand700,
      ),
      hintStyle: AppText.bodyStyle(
        size: 13,
        weight: FontWeight.w400,
        color: AppColors.inkFaint,
      ),
      prefixIconColor: AppColors.brand700,
      suffixIconColor: AppColors.inkFaint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.brand500, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.rejectedFg, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.rejectedFg, width: 1.8),
      ),
      errorStyle: AppText.bodyStyle(size: 11, color: AppColors.rejectedFg),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand900,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.brand900.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        elevation: 0,
        textStyle: AppText.bodyStyle(size: 13.5, weight: FontWeight.w700, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand900,
        side: const BorderSide(color: AppColors.brand900, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        textStyle: AppText.bodyStyle(size: 13.5, weight: FontWeight.w700, color: AppColors.brand900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand900,
        textStyle: AppText.bodyStyle(size: 12.5, weight: FontWeight.w600, color: AppColors.brand900),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      titleTextStyle: AppText.bodyStyle(size: 16, weight: FontWeight.w700, color: AppColors.brand900),
      contentTextStyle: AppText.bodyStyle(size: 13, weight: FontWeight.w400, color: AppColors.inkSoft),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.bodyStyle(size: 12.5, weight: FontWeight.w600, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.brand900,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.55),
      selectedLabelStyle: AppText.bodyStyle(size: 11, weight: FontWeight.w700, color: Colors.white),
      unselectedLabelStyle: AppText.bodyStyle(size: 11, weight: FontWeight.w500, color: Colors.white70),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brand700,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.brand700 : AppColors.surface,
      ),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      headerBackgroundColor: AppColors.brand900,
      headerForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  );
}