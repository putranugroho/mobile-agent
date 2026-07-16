// lib/theme/app_typography.dart
//
// Tiga peran tipografi yang bertingkat, meniru konsep redesain:
//  - Fraunces (serif)      -> judul & sapaan, terasa hangat & "mahal"
//  - Plus Jakarta Sans     -> UI/body, netral dan sangat mudah dibaca
//  - IBM Plex Mono         -> angka, nominal, NIK, ID — terasa presisi
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  AppText._();

  static const String display = 'Fraunces';
  static const String body = 'PlusJakartaSans';
  static const String mono = 'IBMPlexMono';

  /// Judul besar bergaya serif — dipakai untuk sapaan seperti
  /// "Selamat Datang" pada layar Masuk.
  static TextStyle displayStyle({
    double size = 22,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.brand900,
    double letterSpacing = -0.2,
    double? height,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Teks UI/body umum — label, tombol, deskripsi, nama.
  static TextStyle bodyStyle({
    double size = 13.5,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: body,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Teks data presisi — nominal Rupiah, NIK, nomor HP, ID.
  static TextStyle monoStyle({
    double size = 12.5,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Label kecil huruf kapital dengan letter-spacing lebar — dipakai
  /// untuk eyebrow/section label dan tag berputar seperti "MENUNGGU".
  static TextStyle eyebrow({
    double size = 11,
    Color color = AppColors.gold600,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 1.4,
  }) {
    return TextStyle(
      fontFamily: body,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}