// lib/pages/histori_permohonan_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/permohonan_pinjaman_notifier.dart';
import '../models/permohonan_pinjaman_model.dart';
import '../theme/app_colors.dart';
import '../widgets/pengajuan_card.dart';
import 'detail_permohonan_page.dart';

class HistoriPermohonanPage extends StatelessWidget {
  final bool isEmbedded;

  const HistoriPermohonanPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: isEmbedded
          ? null
          : AppBar(
              title: const Text('Histori Proses'),
              centerTitle: true,
            ),
      body: ChangeNotifierProvider(
        create: (context) => PengajuanNotifier()..loadHistori(),
        child: Consumer<PengajuanNotifier>(
          builder: (context, notifier, child) {
            if (notifier.isLoadingHistori && notifier.historiData.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brand700),
              );
            }

            if (notifier.errorMessageHistori.isNotEmpty) {
              return PengajuanStateMessage(
                icon: Icons.cloud_off_rounded,
                message: notifier.errorMessageHistori,
                actionLabel: 'Coba Lagi',
                onAction: () => notifier.loadHistori(),
              );
            }

            if (notifier.historiData.isEmpty) {
              return const PengajuanStateMessage(
                icon: Icons.history_rounded,
                message: 'Belum ada histori proses',
              );
            }

            return RefreshIndicator(
              color: AppColors.brand700,
              onRefresh: notifier.refreshHistori,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                itemCount: notifier.historiData.length,
                itemBuilder: (context, index) {
                  final item = notifier.historiData[index];
                  return PengajuanCard(
                    nama: item.nama,
                    noHp: item.noHp,
                    status: item.status,
                    nominalText: _formatRupiah(item.nilaiPinjaman),
                    tanggalText: _formatDate(item.tglinput),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPermohonanPage(
                            data: item,
                            notifier: notifier,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
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
