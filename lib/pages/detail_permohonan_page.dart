// lib/pages/detail_permohonan_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/permohonan_pinjaman_model.dart';
import '../notifiers/permohonan_pinjaman_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/approval_stamp_overlay.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/gradient_button.dart';
import '../widgets/seal_ring.dart';
import '../widgets/status_pill.dart';

/// Data mentah satu baris info sebelum dirender — dipakai supaya baris
/// TERAKHIR di tiap [InfoCard] otomatis tidak digambar garis pemisahnya
/// (lihat [_rowsFrom]), tanpa harus menghitung index secara manual di
/// setiap tempat yang memakainya.
class _RowSpec {
  final String label;
  final String value;
  final bool mono;
  final bool emphasize;
  const _RowSpec(this.label, this.value, {this.mono = false, this.emphasize = false});
}

List<Widget> _rowsFrom(List<_RowSpec> rows) {
  return [
    for (int i = 0; i < rows.length; i++)
      DetailRow(
        label: rows[i].label,
        value: rows[i].value,
        mono: rows[i].mono,
        emphasize: rows[i].emphasize,
        isLast: i == rows.length - 1,
      ),
  ];
}

class DetailPermohonanPage extends StatefulWidget {
  final PengajuanModel data;
  final PengajuanNotifier notifier;

  const DetailPermohonanPage({super.key, required this.data, required this.notifier});

  @override
  State<DetailPermohonanPage> createState() => _DetailPermohonanPageState();
}

class _DetailPermohonanPageState extends State<DetailPermohonanPage> {
  late DateTime selectedDate;
  late DateTime tanggalPengajuan;
  late DateTime today;

  @override
  void initState() {
    super.initState();
    tanggalPengajuan = _parseDateOnly(widget.data.tglinput);
    today = DateTime.now();
    selectedDate = today;
  }

  @override
  Widget build(BuildContext context) {
    final bool isProcessed = widget.data.status == '2' || widget.data.status == '3';

    final pemohonRows = _rowsFrom([
      _RowSpec('No CIF', widget.data.noCif.isNotEmpty ? widget.data.noCif : '-', mono: true),
      _RowSpec('No ID (KTP)', widget.data.noId, mono: true),
      _RowSpec('Nama Lengkap', widget.data.nama),
      _RowSpec('No HP', widget.data.noHp, mono: true),
      _RowSpec('Alamat', widget.data.alamat),
    ]);

    final pinjamanSpecs = <_RowSpec>[
      _RowSpec('Nominal', _formatRupiah(widget.data.nilaiPinjaman), mono: true, emphasize: true),
      _RowSpec('Jangka Waktu', '${widget.data.jkWaktu} bulan'),
      _RowSpec('Suku Bunga', '${widget.data.rate}%'),
      _RowSpec('Cicilan/bulan', _formatRupiah(widget.data.cicilanPerbulan), mono: true),
      _RowSpec('Tgl Pengajuan', _formatDate(widget.data.tglinput)),
      if (widget.data.userHandle.isNotEmpty) _RowSpec('User Handle', widget.data.userHandle),
      if (widget.data.tglproses.isNotEmpty) _RowSpec('Tanggal Proses', _formatDate(widget.data.tglproses)),
      if (widget.data.tglkeputusan.isNotEmpty) _RowSpec('Tgl Keputusan', _formatDate(widget.data.tglkeputusan)),
      _RowSpec('Status', statusLabelFor(widget.data.status)),
      if (widget.data.alasan.isNotEmpty) _RowSpec('Alasan', widget.data.alasan),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 18),

            const SectionEyebrow(title: 'Data Pemohon'),
            InfoCard(children: pemohonRows),
            const SizedBox(height: 18),

            const SectionEyebrow(title: 'Data Jaminan'),
            InfoCard(children: [
              DetailRow(label: 'Jenis Jaminan', value: widget.notifier.getNamaJaminan(widget.data.kdJaminan)),
              _buildFotoJaminan(),
            ]),
            const SizedBox(height: 18),

            const SectionEyebrow(title: 'Data Pinjaman'),
            InfoCard(children: _rowsFrom(pinjamanSpecs)),
            const SizedBox(height: 18),

            _buildTanggalKeputusan(isProcessed),

            if (!isProcessed) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: OutlinedButton(
                      onPressed: () => _showAlasanDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.rejectedFg,
                        side: const BorderSide(color: Color(0xFFE3BCB5), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: Text('Tolak', style: AppText.bodyStyle(size: 13.5, weight: FontWeight.w700, color: AppColors.rejectedFg)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 13,
                    child: GradientButton(
                      label: 'Setuju',
                      icon: Icons.check_circle_outline,
                      gradient: AppGradients.approve,
                      shadowTint: AppColors.brand700,
                      onPressed: () => _showConfirmDialog('SETUJU', '2', 'Apakah Anda yakin ingin menyetujui pengajuan ini?'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== HERO: ringkasan pemohon + status ==========
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          SealRing(
            size: 52,
            ringWidth: 2.4,
            child: SealInitials(text: SealInitials.initialsOf(widget.data.nama), fontSize: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStyle(size: 14, weight: FontWeight.w700, color: AppColors.brand900),
                ),
                const SizedBox(height: 3),
                Text('NIK ${widget.data.noId}', style: AppText.monoStyle(size: 10.5, color: AppColors.inkFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            status: widget.data.status,
            label: statusLabelFor(widget.data.status),
            fontSize: 10.5,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          ),
        ],
      ),
    );
  }

  // ========== FOTO JAMINAN ==========
  Widget _buildFotoJaminan() {
    final fhotoJaminan = widget.data.fhotojaminan;

    Widget inner;
    if (fhotoJaminan.isEmpty) {
      inner = const Icon(Icons.image_not_supported_outlined, size: 22, color: AppColors.inkFaint);
    } else {
      try {
        String base64String = fhotoJaminan;
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        final bytes = base64Decode(base64String);
        inner = SizedBox.expand(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image_outlined, size: 22, color: AppColors.inkFaint);
            },
          ),
        );
      } catch (e) {
        inner = const Icon(Icons.error_outline, size: 22, color: AppColors.inkFaint);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              'Foto Jaminan',
              style: AppText.bodyStyle(size: 11, weight: FontWeight.w600, color: AppColors.inkFaint),
            ),
          ),
          const SizedBox(width: 8),
          SealRing(size: 56, ringWidth: 2, squircle: true, innerColor: AppColors.surfaceAlt, child: inner),
        ],
      ),
    );
  }

  // ========== TANGGAL KEPUTUSAN ==========
  Widget _buildTanggalKeputusan(bool isProcessed) {
    if (isProcessed) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggal Keputusan', style: AppText.bodyStyle(size: 12.5, weight: FontWeight.w700, color: AppColors.brand900)),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: tanggalPengajuan,
                lastDate: today,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: AppColors.brand900, onPrimary: Colors.white),
                  ),
                  child: child!,
                ),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.brand300, width: 1.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: AppColors.brand700),
                      const SizedBox(width: 8),
                      Text(_formatDateOnly(selectedDate), style: AppText.bodyStyle(size: 13, weight: FontWeight.w600, color: AppColors.ink)),
                    ],
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: AppColors.brand900.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.brand900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Min: ${_formatDateOnly(tanggalPengajuan)}   ·   Maks: ${_formatDateOnly(today)}',
            style: AppText.bodyStyle(size: 9.5, weight: FontWeight.w400, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String action, String status, String message) {
    final bool approving = status == '2';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Icon(
              approving ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: approving ? AppColors.brand700 : AppColors.rejectedFg,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('Konfirmasi $action', style: AppText.bodyStyle(size: 16, weight: FontWeight.w700, color: AppColors.brand900)),
          ],
        ),
        content: Text(message, style: AppText.bodyStyle(size: 13, color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: AppText.bodyStyle(size: 13, weight: FontWeight.w600, color: AppColors.inkFaint)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // tutup dialog konfirmasi

              // Kunci layar selama request ke server berjalan, supaya user
              // tahu prosesnya sedang berjalan dan tidak mengira aplikasi
              // diam/hang, dan tidak bisa pencet tombol lagi selagi menunggu.
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.brand700)),
              );

              final success = await widget.notifier.updateStatus(
                noId: widget.data.noId,
                noHp: widget.data.noHp,
                status: status,
                alasan: status == '2' ? 'keputusan sesuai hasil evaluasi' : 'Tidak ada alasan',
                tglKeputusan: _formatDateOnly(selectedDate),
              );

              // PENTING: pakai `mounted`/`context` milik State halaman ini,
              // BUKAN context dari `builder` di atas — dialog konfirmasi itu
              // sudah ditutup duluan sehingga context-nya sudah tidak
              // mounted lagi begitu request selesai. Kalau dicek pakai
              // context dialog, hasilnya selalu false dan pop up
              // berhasil/gagal jadi tidak pernah muncul walau requestnya
              // sukses di server (baru ketahuan pas dicoba proses ulang dan
              // ditolak karena datanya sudah diproses sebelumnya).
              if (!mounted) return;
              Navigator.pop(context); // tutup loading indicator

              // Momen istimewa: animasi cap emas–hijau tepat saat pengajuan
              // disetujui. Murni dekoratif, tidak mengubah alur/logika.
              if (success && status == '2') {
                await showApprovalStamp(context);
              }

              if (!mounted) return;
              _showResultDialog(success, action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approving ? AppColors.brand700 : AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('Ya, $action', style: AppText.bodyStyle(size: 13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAlasanDialog() {
    String alasan = '';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Alasan Penolakan', style: AppText.bodyStyle(size: 16, weight: FontWeight.w700, color: AppColors.brand900)),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Masukkan alasan penolakan...'),
          style: AppText.bodyStyle(size: 13),
          onChanged: (value) => alasan = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: AppText.bodyStyle(size: 13, weight: FontWeight.w600, color: AppColors.inkFaint)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showConfirmDialog('TOLAK', '3', 'Apakah Anda yakin ingin menolak pengajuan ini?');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('Lanjutkan', style: AppText.bodyStyle(size: 13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(bool success, String action) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? AppColors.brand700 : AppColors.rejectedFg,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Berhasil' : 'Gagal', style: AppText.bodyStyle(size: 16, weight: FontWeight.w700, color: AppColors.brand900)),
          ],
        ),
        content: Text(
          success ? 'Pengajuan berhasil di$action' : 'Gagal mengupdate status. Silakan coba lagi.',
          style: AppText.bodyStyle(size: 13, color: AppColors.inkSoft),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // tutup dialog hasil
              // Kalau berhasil, proses sudah tuntas — otomatis balik ke
              // halaman daftar supaya tidak "nyangkut" di halaman detail
              // dan user gak bingung apakah harus ngapain lagi.
              if (success) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success ? AppColors.brand700 : AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text('OK', style: AppText.bodyStyle(size: 13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  DateTime _parseDateOnly(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateTimeStr.split('T')[0]);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDate(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr.split('T')[0];
    }
  }

  String _formatDateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatRupiah(String value) {
    final raw = value.toString().trim();

    if (raw.isEmpty || raw == '-' || raw.toLowerCase() == 'null') {
      return 'Rp 0';
    }

    try {
      final number = double.tryParse(raw) ?? 0;
      final intValue = number.round();

      return 'Rp ${intValue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    } catch (e) {
      return 'Rp $raw';
    }
  }
}