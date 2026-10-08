// lib/pages/hari_libur_page.dart
//
// Ditampilkan sebagai pengganti halaman menu kalau petugas coba login pas
// hari libur (libur_nasional, cuti_bersama, libur_khusus yang berlaku
// buat BPR dia, atau hari libur mingguan dari jam kerja). Sesi server
// sudah di-logout & sesi lokal sudah dibersihkan sebelum sampai ke sini —
// jadi ini bukan cuma "layar penghalang" doang, petugas beneran belum
// login.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

class HariLiburPage extends StatelessWidget {
  final String? keterangan;

  const HariLiburPage({super.key, this.keterangan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/hari_libur.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hari Libur',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    keterangan != null && keterangan!.isNotEmpty
                        ? 'Hari ini adalah "$keterangan".\nSistem tidak bisa diakses pada hari libur.\nSilahkan kembali lagi pada hari kerja'
                        : 'Hari ini adalah hari libur.\nSistem tidak bisa diakses pada hari libur.\nSilahkan kembali lagi pada hari kerja',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Kembali ke Halaman Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}