// lib/widgets/status_pill.dart
//
// Badge status pengajuan yang konsisten di seluruh aplikasi (daftar,
// histori, detail). Kode status dari backend TIDAK berubah — '0','1','2','3'
// tetap sama persis, hanya tampilan visual dan pemetaan warnanya yang
// dirapikan mengikuti palet pending/process/approved/rejected.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class StatusStyle {
  final Color background;
  final Color foreground;
  const StatusStyle(this.background, this.foreground);
}

StatusStyle statusStyleFor(String status) {
  switch (status.trim()) {
    case '0':
      return const StatusStyle(AppColors.pendingBg, AppColors.pendingFg);
    case '1':
      return const StatusStyle(AppColors.processBg, AppColors.processFg);
    case '2':
      return const StatusStyle(AppColors.approvedBg, AppColors.approvedFg);
    case '3':
      return const StatusStyle(AppColors.rejectedBg, AppColors.rejectedFg);
    default:
      return StatusStyle(AppColors.border.withOpacity(0.6), AppColors.inkFaint);
  }
}

/// Label baku untuk tiap kode status — dipakai bersama oleh daftar,
/// histori, dan detail supaya kata yang muncul selalu sama persis
/// dengan nama warna semantiknya (pending/process/approved/rejected).
/// Kode status ('0'..'3') dari backend tidak disentuh, hanya labelnya.
String statusLabelFor(String status) {
  switch (status.trim()) {
    case '0':
      return 'Menunggu';
    case '1':
      return 'Diproses';
    case '2':
      return 'Disetujui';
    case '3':
      return 'Ditolak';
    default:
      return '-';
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final String label;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusPill({
    super.key,
    required this.status,
    required this.label,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final style = statusStyleFor(status);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.bodyStyle(size: fontSize, weight: FontWeight.w700, color: style.foreground),
      ),
    );
  }
}