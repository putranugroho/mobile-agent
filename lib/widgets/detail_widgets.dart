// lib/widgets/detail_widgets.dart
//
// Komponen kecil yang dipakai berulang pada layar-layar berisi data
// terstruktur (Detail Pengajuan, Profil): judul section dengan bar emas,
// kartu info, dan baris label-nilai bergaris putus-putus.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Judul section dengan bar emas kecil di depan — versi rapi dari
/// `_buildSectionTitle` lama, tanpa mengubah urutan/isi section itu sendiri.
class SectionEyebrow extends StatelessWidget {
  final String title;
  const SectionEyebrow({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 15,
            decoration: BoxDecoration(color: AppColors.gold600, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppText.bodyStyle(size: 11.5, weight: FontWeight.w700, color: AppColors.brand900, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

/// Kartu putih dengan border tipis & shadow lembut — pembungkus seragam
/// untuk kartu info, kartu hero, dan kartu keputusan.
class InfoCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const InfoCard({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 4)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

/// Satu baris label-nilai di dalam [InfoCard], dengan garis pemisah putus
/// halus antar baris — meniru `.drow` pada konsep redesain.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool emphasize;
  final bool isLast;
  final double labelWidth;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.emphasize = false,
    this.isLast = false,
    this.labelWidth = 112,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: AppText.bodyStyle(size: 11, weight: FontWeight.w600, color: AppColors.inkFaint)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? AppText.monoStyle(
                      size: emphasize ? 13.5 : 12,
                      weight: emphasize ? FontWeight.w700 : FontWeight.w500,
                      color: emphasize ? AppColors.brand700 : AppColors.ink,
                    )
                  : AppText.bodyStyle(size: 12.5, weight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}