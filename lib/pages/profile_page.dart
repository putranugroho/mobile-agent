// lib/pages/profil_page.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../widgets/brand_logo.dart';
import 'login_page.dart';
import 'ganti_password_page.dart';

class ProfilPage extends StatelessWidget {
  final String userName;
  final String bprId;
  final String userId;

  const ProfilPage({
    super.key,
    required this.userName,
    required this.bprId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.canvas,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: BrandColors.brand900,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Hero card =====
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: BrandGradients.hero,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.brand900.withOpacity(0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SealInitials(name: userName, size: 92, ringWidth: 3, fontSize: 32),
                  const SizedBox(height: 18),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BrandColors.gold400.withOpacity(0.55)),
                    ),
                    child: Text(
                      'ID Petugas: ${userId.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== Info card =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColors.border),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.brand900.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoRow(Icons.person_rounded, 'Username', userName),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _infoRow(Icons.store_rounded, 'BPR ID', bprId),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _infoRow(Icons.badge_rounded, 'User ID', userId),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== Ganti Password =====
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GantiPasswordPage(
                        bprId: bprId,
                        userId: userId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 20),
                label: const Text('GANTI PASSWORD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.brand900,
                  side: const BorderSide(color: BrandColors.brand700, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ===== Logout =====
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: BrandGradients.danger,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.danger.withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('LOGOUT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: BrandColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: BrandColors.brand700),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: BrandColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Konfirmasi Logout', style: TextStyle(fontSize: 15)),
        content: const Text('Apakah Anda yakin ingin keluar?', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // tutup dialog konfirmasi

              // Kunci interaksi selama proses logout berjalan. Sebelumnya
              // tanpa ini, user bisa keburu pindah tab (Menu Utama) sementara
              // AuthService().logout() masih menunggu respons server (tidak
              // ada timeout + sinyal jelek = bisa lama) — ProfilPage lalu
              // ter-unmount duluan, dan redirect ke Login di bawah batal
              // diam-diam padahal sesi lokal sudah kepalang terhapus.
              // Loading barrier ini mencegah skenario itu.
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              await AuthService().logout(bprId: bprId, userId: userId);

              // Pakai navigatorKey GLOBAL (dari main.dart), bukan context
              // lokal halaman ini. Ini tetap jalan walau context ProfilPage
              // sudah tidak mounted — mis. kalau IndexedStack di atas suatu
              // saat berubah lagi, atau widget ini dibuka dari alur lain.
              // pushAndRemoveUntil dengan predicate false otomatis menutup
              // dialog loading di atas juga, jadi tidak perlu pop manual.
              appNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
