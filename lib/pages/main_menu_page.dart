// lib/pages/main_menu_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../repositories/permohonan_pinjaman_repository.dart';
import '../network/network.dart';
import '../widgets/brand_logo.dart';
import 'daftar_permohonan_page.dart';
import 'permohonan_histori_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class MainMenuPage extends StatefulWidget {
  final String userName;
  final String bprId;
  final String userId;

  const MainMenuPage({
    super.key,
    required this.userName,
    required this.bprId,
    required this.userId,
  });

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;        // ← waktu pertama kali back ditekan

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MainMenuContent(
        userName: widget.userName,
        bprId: widget.bprId,
      ),
      ProfilPage(
        userName: widget.userName,
        bprId: widget.bprId,
        userId: widget.userId,
      ),
    ];
  }

  /// Dipanggil oleh PopScope saat back ditekan.
  /// Return true = biarkan sistem handle (keluar app), false = kita handle sendiri.
  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    final isFirstPress =
        _lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2);

    if (isFirstPress) {
      // Pertama kali → tampilkan snackbar, jangan keluar
      _lastBackPressed = now;
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tekan sekali lagi untuk keluar'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: const Color(0xff0F3D2E),
          ),
        );
      }
      return false; // jangan keluar dulu
    }

    // Kedua kali dalam 2 detik → logout lalu exit
    await _logoutAndExit();
    return false; // kita yang handle via SystemNavigator
  }

  Future<void> _logoutAndExit() async {
    try {
      final authService = AuthService();
      await authService.logoutCurrentSession();
    } catch (e) {
      debugPrint('❌ Logout on exit error: $e');
    }

    // SystemNavigator.pop() TIDAK menjamin proses/isolate Flutter benar-benar
    // mati — di Android kadang cuma activity yang di-finish(), dan kalau
    // user buka lagi dari recent-apps sebelum OS betul-betul evict proses,
    // widget tree lama (halaman ini) bisa ter-resume apa adanya. Karena
    // logoutCurrentSession() di atas sudah menghapus sesi lokal, redirect
    // eksplisit ke LoginPage dulu supaya kalau itu terjadi, yang muncul
    // saat resume adalah halaman Login yang benar — bukan halaman ini
    // dengan bpr_id yang sudah kosong.
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false → kita intercept semua back gesture
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // sudah di-pop sistem, skip
        await _onWillPop();
      },
      child: Scaffold(
        // PENTING: pakai IndexedStack, BUKAN `_pages[_selectedIndex]` langsung.
        // Cara lama membongkar (unmount) halaman yang sedang tidak aktif
        // begitu tab diganti. Kalau itu terjadi SAAT ProfilPage masih
        // menunggu proses logout (network call tanpa timeout, bisa lama
        // di sinyal buruk), context ProfilPage jadi invalid pas logout
        // selesai → redirect ke LoginPage batal diam-diam, padahal sesi
        // lokal sudah kepalang dihapus. IndexedStack menjaga semua tab
        // tetap hidup di tree, cuma disembunyikan.
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            gradient: BrandGradients.header,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.55),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Menu Utama',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenuContent extends StatefulWidget {
  final String userName;
  final String bprId;

  const MainMenuContent({
    super.key,
    required this.userName,
    required this.bprId,
  });

  @override
  State<MainMenuContent> createState() => _MainMenuContentState();
}

class _MainMenuContentState extends State<MainMenuContent> {
  String _selectedMenu = 'permohonan';
  String? _logoBprUrl;

  @override
  void initState() {
    super.initState();
    _loadLogoBpr();
  }

  Future<void> _loadLogoBpr() async {
    final repo = PengajuanRepository();
    final filename = await repo.getBprLogoFilename(widget.bprId);
    if (filename != null && filename.isNotEmpty && mounted) {
      setState(() {
        _logoBprUrl = NetworkUrl.getLogoBpr(filename);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.canvas,
      appBar: AppBar(
        toolbarHeight: 66,
        title: Row(
          children: [
            // Zona 1: logo medfo, rapat ke pinggir kiri
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Image.asset(
                        'assets/logo_medfo_agent_trimmed.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Zona 2: zona aman kosong, tidak diisi apa-apa
            const Expanded(flex: 1, child: SizedBox.shrink()),
            // Zona 3: logo BPR, rapat ke pinggir kanan
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2, top: 2, bottom: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 96,
                      height: 56,
                      child: _logoBprUrl != null
                          ? Image.network(
                              _logoBprUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('=== IMAGE ERROR: $error');
                                return _logoFallback();
                              },
                            )
                          : _logoFallback(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff0F3D2E),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: BrandGradients.hero),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SealInitials(name: widget.userName, size: 46, fontSize: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang,',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Text(
                          'BPR_ID: ${widget.bprId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: BrandColors.canvas,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                _buildMenuChip('Permohonan Pinjaman', _selectedMenu == 'permohonan', () {
                  setState(() => _selectedMenu = 'permohonan');
                }),
                const SizedBox(width: 12),
                _buildMenuChip('Histori Proses', _selectedMenu == 'histori', () {
                  setState(() => _selectedMenu = 'histori');
                }),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: BrandColors.canvas,
              child: _selectedMenu == 'permohonan'
                  ? const DaftarPermohonanPage(isEmbedded: true)
                  : const HistoriPermohonanPage(isEmbedded: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.business, size: 24, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildMenuChip(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? BrandGradients.button : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.transparent : BrandColors.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: BrandColors.brand900.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : BrandColors.inkSoft,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Konfirmasi Logout', style: TextStyle(fontSize: 16)),
        content: const Text('Apakah Anda yakin ingin keluar?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}