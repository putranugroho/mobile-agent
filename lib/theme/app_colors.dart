// lib/theme/app_colors.dart
//
// Palet warna identitas visual "Mobile Agent". Hijau tua BPR tetap jadi
// jangkar identitas (tidak diganti — sama dengan seed color lama), hanya
// diberi kedalaman lewat gradasi dan dipasangkan dengan aksen emas-perunggu
// yang dipakai secukupnya sebagai motif "cap resmi" persetujuan.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---------- Ink (teks) ----------
  static const Color ink = Color(0xFF12241C);
  static const Color inkSoft = Color(0xFF5B6B62);
  static const Color inkFaint = Color(0xFF8B9A92);

  // ---------- Permukaan ----------
  static const Color canvas = Color(0xFFF5F8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEAF3EE);
  static const Color border = Color(0xFFE1E8E2);

  // ---------- Brand hijau (jangkar identitas BPR) ----------
  static const Color brand900 = Color(0xFF0F3D2E);
  static const Color brand700 = Color(0xFF1B5C43);
  static const Color brand500 = Color(0xFF2E8B62);
  static const Color brand300 = Color(0xFF8FC3A8);

  // ---------- Aksen emas-perunggu (motif tanda tangan) ----------
  static const Color gold600 = Color(0xFFB8873B);
  static const Color gold100 = Color(0xFFF3E6CB);

  // ---------- Status pengajuan ----------
  static const Color pendingBg = Color(0xFFFBF1DE);
  static const Color pendingFg = Color(0xFF96702A);
  static const Color processBg = Color(0xFFE9F2F8);
  static const Color processFg = Color(0xFF2F6382);
  static const Color approvedBg = Color(0xFFE7F3EC);
  static const Color approvedFg = Color(0xFF1B5C43);
  static const Color rejectedBg = Color(0xFFFBEBE8);
  static const Color rejectedFg = Color(0xFF963228);

  // ---------- Bahaya / destruktif ----------
  static const Color danger = Color(0xFFB0453A);
}