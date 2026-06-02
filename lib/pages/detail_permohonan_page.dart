// lib/pages/detail_permohonan_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/permohonan_pinjaman_model.dart';
import '../notifiers/permohonan_pinjaman_notifier.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengajuan'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff0F3D2E),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Pemohon
            _buildSectionTitle('Data Pemohon'),
            const SizedBox(height: 6),
            _buildInfoCard([
              _detailRow('No CIF', widget.data.noCif.isNotEmpty ? widget.data.noCif : '-'),
              _detailRow('No ID (KTP)', widget.data.noId),
              _detailRow('Nama Lengkap', widget.data.nama),
              _detailRow('No HP', widget.data.noHp),
              _detailRow('Alamat', widget.data.alamat),
            ]),
            const SizedBox(height: 16),

            // Data Jaminan
            _buildSectionTitle('Data Jaminan'),
            const SizedBox(height: 6),
            _buildInfoCard([_detailRow('Jenis Jaminan', widget.notifier.getNamaJaminan(widget.data.kdJaminan)), _buildFotoJaminan()]),
            const SizedBox(height: 16),

            // Data Pinjaman
            _buildSectionTitle('Data Pinjaman'),
            const SizedBox(height: 6),
            _buildInfoCard([
              _detailRow('Nominal', _formatRupiah(widget.data.nilaiPinjaman)),
              _detailRow('Jangka Waktu', '${widget.data.jkWaktu} bulan'),
              _detailRow('Suku Bunga', '${widget.data.rate}%'),
              _detailRow('Cicilan', _formatRupiah(widget.data.cicilanPerbulan)),
              _detailRow('Tanggal Pengajuan', _formatDate(widget.data.tglinput)),

              if (widget.data.userHandle.isNotEmpty) _detailRow('User Handle', widget.data.userHandle),

              if (widget.data.tglproses.isNotEmpty) _detailRow('Tanggal Proses', _formatDate(widget.data.tglproses)),

              if (widget.data.tglkeputusan.isNotEmpty) _detailRow('Tanggal Keputusan', _formatDate(widget.data.tglkeputusan)),

              _detailRow('Status', _getStatusText(widget.data.status)),

              if (widget.data.alasan.isNotEmpty) _detailRow('Alasan', widget.data.alasan),
            ]),
            const SizedBox(height: 16),

            // Tanggal Keputusan
            _buildTanggalKeputusan(),
            const SizedBox(height: 16),

            // Update Status
            if (!isProcessed) ...[
              _buildSectionTitle('Update Status'),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showConfirmDialog('SETUJU', '2', 'Apakah Anda yakin ingin menyetujui pengajuan ini?'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('SETUJU', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAlasanDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('TOLAK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // ========== WIDGET FOTO JAMINAN (TANPA CONTAINER LUAR) ==========
  Widget _buildFotoJaminan() {
    final fhotoJaminan = widget.data.fhotojaminan;

    // Jika tidak ada foto atau string kosong
    if (fhotoJaminan == null || fhotoJaminan.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 110,
              child: Text(
                'Foto Jaminan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
              child: const Center(child: Icon(Icons.image_not_supported, size: 24, color: Colors.grey)),
            ),
          ],
        ),
      );
    }

    // Coba decode base64
    try {
      String base64String = fhotoJaminan;
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      final bytes = base64Decode(base64String);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 110,
              child: Text(
                'Foto Jaminan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                bytes,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 110,
              child: Text(
                'Foto Jaminan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.error_outline, size: 24, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: const Color(0xff0F3D2E)),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.trim()) {
      case '0':
        return 'Belum Diproses';
      case '1':
        return 'Proses';
      case '2':
        return 'Disetujui';
      case '3':
        return 'Ditolak';
      default:
        return '-';
    }
  }

  Widget _buildTanggalKeputusan() {
    final bool isProcessed = widget.data.status == '2' || widget.data.status == '3';

    // Jika status sudah diproses (2/3), jangan tampilkan sama sekali
    if (isProcessed) {
      return const SizedBox.shrink(); // Tidak menampilkan apa-apa
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tanggal Keputusan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff0F3D2E)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: tanggalPengajuan,
                lastDate: today,
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: Color(0xff0F3D2E), onPrimary: Colors.white),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff0F3D2E).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: const Color(0xff0F3D2E)),
                      const SizedBox(width: 6),
                      Text(_formatDateOnly(selectedDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xff0F3D2E).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xff0F3D2E)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Min: ${_formatDateOnly(tanggalPengajuan)} | Max: ${_formatDateOnly(today)}',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String action, String status, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(status == '2' ? Icons.check_circle : Icons.cancel, color: status == '2' ? Colors.green : Colors.red, size: 24),
            const SizedBox(width: 8),
            Text('Konfirmasi $action', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await widget.notifier.updateStatus(
                noId: widget.data.noId,
                noHp: widget.data.noHp,
                status: status,
                alasan: status == '2' ? 'keputusan sesuai hasil evaluasi' : 'Tidak ada alasan',
                tglKeputusan: _formatDateOnly(selectedDate),
              );
              if (context.mounted) {
                Navigator.pop(context);
                _showResultDialog(success, action);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: status == '2' ? Colors.green : Colors.red, foregroundColor: Colors.white),
            child: Text('Ya, $action', style: const TextStyle(fontSize: 13)),
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
        title: const Text('Alasan Penolakan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Masukkan alasan penolakan...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (value) => alasan = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showConfirmDialog('TOLAK', '3', 'Apakah Anda yakin ingin menolak pengajuan ini?');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Lanjutkan', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(bool success, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Berhasil' : 'Gagal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(success ? 'Pengajuan berhasil di$action' : 'Gagal mengupdate status. Silakan coba lagi.', style: const TextStyle(fontSize: 13)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: success ? Colors.green : Colors.red),
            child: const Text('OK', style: TextStyle(fontSize: 13)),
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
