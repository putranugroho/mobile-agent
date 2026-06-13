// lib/pages/main_menu_page.dart
import 'package:flutter/material.dart';
import '../repositories/permohonan_pinjaman_repository.dart';
import '../network/network.dart';
import 'daftar_permohonan_page.dart';
import 'permohonan_histori_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xff0F3D2E),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xff0F3D2E),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Menu Utama',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
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
      backgroundColor: const Color(0xffEAF3EE),
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo kiri (medfo) — dari asset
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo_medfo_agent.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),

            // Logo kanan (BPR) — dari API
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: _logoBprUrl != null
                    ? Image.network(
                        _logoBprUrl!,
                        fit: BoxFit.cover,
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
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff0F3D2E),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xff0F3D2E),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BPR_ID: ${widget.bprId}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xffEAF3EE),
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
              color: const Color(0xffEAF3EE),
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
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff0F3D2E) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? const Color(0xff0F3D2E) : const Color(0xffD0D8D3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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