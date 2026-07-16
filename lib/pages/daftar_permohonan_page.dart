// lib/pages/daftar_permohonan_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/permohonan_pinjaman_notifier.dart';
import '../models/permohonan_pinjaman_model.dart';
import 'detail_permohonan_page.dart';

class DaftarPermohonanPage extends StatelessWidget {
  final bool isEmbedded;

  const DaftarPermohonanPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAF3EE),
      appBar: isEmbedded
          ? null
          : AppBar(
              title: const Text('Permohonan Pinjaman'),
              backgroundColor: const Color.fromARGB(255, 74, 124, 89),
              foregroundColor: const Color(0xff0F3D2E),
              centerTitle: true,
              elevation: 0,
            ),
      body: ChangeNotifierProvider(
        create: (context) => PengajuanNotifier()..loadPengajuan(),
        child: Consumer<PengajuanNotifier>(
          builder: (context, notifier, child) {
            if (notifier.isLoading && notifier.data.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notifier.errorMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(notifier.errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => notifier.loadPengajuan(), child: const Text('Coba Lagi')),
                  ],
                ),
              );
            }

            if (notifier.data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xffEAF3EE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inbox_rounded, size: 34, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada pengajuan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pengajuan permohonan pinjaman akan tampil di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: notifier.refreshData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                itemCount: notifier.data.length,
                itemBuilder: (context, index) {
                  return _buildCard(notifier.data[index], context, notifier);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(PengajuanModel item, BuildContext context, PengajuanNotifier notifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPermohonanPage(data: item, notifier: notifier),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris 1: Nama + Status badge
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Color(0xff4A7C59)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.nama,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff0F3D2E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(item.status),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 5),

              // Baris 2: No HP
              Row(
                children: [
                  const Icon(Icons.phone, size: 12, color: Color(0xff4A7C59)),
                  const SizedBox(width: 6),
                  Text(item.noHp, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 4),

              // Baris 3: Nilai Pinjaman
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 12, color: Color(0xff4A7C59)),
                  const SizedBox(width: 6),
                  Text(
                    _formatRupiah(item.nilaiPinjaman),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff0F3D2E)),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Baris 4: Tanggal
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(_formatDate(item.tglinput), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.trim()) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.blue;
      case '2':
        return Colors.green;
      case '3':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        return 'Unknown';
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

  String _formatRupiah(String value) {
    if (value.isEmpty) return 'Rp 0';
    try {
      final number = int.parse(value);
      return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    } catch (e) {
      return 'Rp $value';
    }
  }
}
