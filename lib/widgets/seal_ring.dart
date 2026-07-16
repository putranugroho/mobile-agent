// lib/widgets/seal_ring.dart
//
// Motif visual berulang khas identitas baru: sebuah "cincin" tipis
// emas→hijau yang membingkai logo, avatar berinisial, dan foto jaminan.
// Karena aplikasi ini pada dasarnya soal memberi keputusan resmi atas
// suatu pengajuan, cincin yang sama juga muncul sebagai animasi cap
// persetujuan (lihat approval_stamp_overlay.dart) — satu elemen berulang,
// satu momen istimewa.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class SealRing extends StatelessWidget {
  final Widget child;
  final double size;
  final double ringWidth;
  final bool squircle;
  final Color innerColor;

  const SealRing({
    super.key,
    required this.child,
    this.size = 44,
    this.ringWidth = 2.4,
    this.squircle = false,
    this.innerColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    final outerRadius = squircle ? BorderRadius.circular(size * 0.30) : BorderRadius.circular(size / 2);
    final innerRadius = squircle ? BorderRadius.circular((size * 0.30) - ringWidth) : BorderRadius.circular(size / 2);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        gradient: AppGradients.seal,
      ),
      child: ClipRRect(
        borderRadius: innerRadius,
        child: Container(
          color: innerColor,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Isi cincin berupa 1-2 huruf inisial dengan latar hijau tua pekat —
/// dipakai untuk avatar petugas maupun nasabah di seluruh aplikasi.
class SealInitials extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color background;
  final Color color;

  const SealInitials({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.background = AppColors.brand900,
    this.color = Colors.white,
  });

  static String initialsOf(String name, {int maxChars = 2}) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= maxChars ? maxChars : 1).toUpperCase();
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppText.bodyStyle(size: fontSize, weight: FontWeight.w700, color: color),
      ),
    );
  }
}