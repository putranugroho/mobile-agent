// lib/widgets/pengajuan_card.dart
//
// Kartu daftar pengajuan yang dipakai bersama oleh layar Permohonan
// Pinjaman dan Histori Proses supaya keduanya konsisten persis: avatar
// cincin berinisial, badge status, nominal bergaya mono, dan tanggal.
// Struktur/urutan informasi TIDAK berubah dari versi lama — hanya
// dirapikan secara visual.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'seal_ring.dart';
import 'status_pill.dart';

class PengajuanCard extends StatelessWidget {
  final String nama;
  final String noHp;
  final String status;
  final String nominalText;
  final String tanggalText;
  final VoidCallback onTap;

  const PengajuanCard({
    super.key,
    required this.nama,
    required this.noHp,
    required this.status,
    required this.nominalText,
    required this.tanggalText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SealRing(
                  size: 38,
                  ringWidth: 2,
                  child: SealInitials(text: SealInitials.initialsOf(nama), fontSize: 12),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyStyle(size: 12.5, weight: FontWeight.w700, color: AppColors.brand900),
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusPill(status: status, label: statusLabelFor(status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.call_outlined, size: 12, color: AppColors.inkFaint),
                          const SizedBox(width: 5),
                          Text(
                            noHp.isEmpty ? '-' : noHp,
                            style: AppText.bodyStyle(size: 10.5, weight: FontWeight.w500, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        nominalText,
                        style: AppText.monoStyle(size: 12.5, weight: FontWeight.w700, color: AppColors.brand700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 10.5, color: AppColors.inkFaint),
                          const SizedBox(width: 5),
                          Text(
                            tanggalText,
                            style: AppText.bodyStyle(size: 9.5, weight: FontWeight.w400, color: AppColors.inkFaint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tampilan kosong/kesalahan yang dipakai bersama oleh kedua daftar
/// (Permohonan & Histori) supaya gaya "empty state"-nya konsisten.
class PengajuanStateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PengajuanStateMessage({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, size: 30, color: AppColors.brand700),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyStyle(size: 13, weight: FontWeight.w500, color: AppColors.inkSoft),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: AppText.bodyStyle(size: 12.5, weight: FontWeight.w700, color: AppColors.brand900),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}