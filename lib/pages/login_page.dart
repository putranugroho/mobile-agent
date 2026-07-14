// lib/pages/login_page.dart
import 'package:flutter/material.dart';

import '../models/bpr_profile_model.dart';
import '../services/auth_service.dart';
import '../services/bpr_service.dart';
import 'main_menu_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final BprService _bprService = BprService();

  List<BprProfile> _bprOptions = const [];
  BprProfile? _selectedBpr;

  bool _isLoading = false;
  bool _isLoadingBpr = true;
  bool _obscurePassword = true;
  String? _bprLoadError;

  @override
  void initState() {
    super.initState();
    _loadBprList();
  }

  Future<void> _loadBprList() async {
    if (mounted) {
      setState(() {
        _isLoadingBpr = true;
        _bprLoadError = null;
      });
    }

    try {
      final profiles = await _bprService.getActiveBprProfiles();
      if (!mounted) return;

      final previousBprId = _selectedBpr?.bprId;
      BprProfile? selected;

      if (previousBprId != null) {
        for (final profile in profiles) {
          if (profile.bprId == previousBprId) {
            selected = profile;
            break;
          }
        }
      }

      if (selected == null && profiles.length == 1) {
        selected = profiles.first;
      }

      setState(() {
        _bprOptions = profiles;
        _selectedBpr = selected;
        _isLoadingBpr = false;
        _bprLoadError = profiles.isEmpty ? 'Belum ada BPR aktif yang tersedia' : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _bprOptions = const [];
        _selectedBpr = null;
        _isLoadingBpr = false;
        _bprLoadError = _cleanExceptionMessage(e);
      });
    }
  }

  String _cleanExceptionMessage(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring('Exception: '.length) : message;
  }

  Future<void> _openBprPicker() async {
    if (_isLoading || _isLoadingBpr) return;

    if (_bprLoadError != null || _bprOptions.isEmpty) {
      await _loadBprList();
      return;
    }

    FocusScope.of(context).unfocus();

    final selected = await showModalBottomSheet<BprProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BprPickerSheet(profiles: _bprOptions, selectedBprId: _selectedBpr?.bprId),
    );

    if (selected != null && mounted) {
      setState(() => _selectedBpr = selected);
    }
  }

  Future<void> _login() async {
    final selectedBpr = _selectedBpr;
    final userId = _userIdController.text.trim().toUpperCase();
    final password = _passwordController.text;

    if (_isLoadingBpr) {
      _showErrorDialog('Daftar BPR masih dimuat. Silakan coba kembali.');
      return;
    }

    if (_bprLoadError != null) {
      _showErrorDialog('Daftar BPR belum berhasil dimuat.\n$_bprLoadError');
      return;
    }

    if (selectedBpr == null) {
      _showErrorDialog('Silakan pilih BPR terlebih dahulu');
      return;
    }

    if (userId.isEmpty) {
      _showErrorDialog('User ID tidak boleh kosong');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Password tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(bprId: selectedBpr.bprId, userId: userId, password: password);

      if (!mounted) return;

      if (!result.isSuccess) {
        _showErrorDialog(result.message);
        return;
      }

      final session = await _authService.getSessionData();
      final sessionBprId = session['bpr_id']?.trim() ?? '';
      final sessionUserId = session['user_id']?.trim() ?? '';

      if (sessionBprId.isEmpty || sessionUserId.isEmpty) {
        await _authService.clearSession();
        if (!mounted) return;

        _showErrorDialog('Login berhasil, tetapi data session tidak lengkap. Silakan login kembali.');
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainMenuPage(userName: session['nama'] ?? result.user?.nama ?? '', bprId: sessionBprId, userId: sessionUserId),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal terhubung ke server.\nPeriksa koneksi Anda.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Login Gagal', style: TextStyle(fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showLupaSandiDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xff0F3D2E), size: 24),
            SizedBox(width: 8),
            Text('Informasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Mohon hubungi pihak administrasi', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 13, color: Color(0xff0F3D2E))),
          ),
        ],
      ),
    );
  }

  Widget _buildBprField() {
    final selected = _selectedBpr;

    Widget suffix;
    if (_isLoadingBpr) {
      suffix = const Padding(
        padding: EdgeInsets.all(13),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (_bprLoadError != null) {
      suffix = const Icon(Icons.refresh, size: 21);
    } else {
      suffix = const Icon(Icons.arrow_drop_down, size: 24);
    }

    return InkWell(
      onTap: _openBprPicker,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        isEmpty: selected == null,
        decoration: InputDecoration(
          labelText: '',
          hintText: _isLoadingBpr ? 'Memuat daftar BPR...' : 'Pilih nama BPR',
          prefixIcon: const Icon(Icons.account_balance, size: 20),
          suffixIcon: suffix,
          errorText: _bprLoadError,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: selected == null
            ? Text(_isLoadingBpr ? 'Memuat daftar BPR...' : 'Pilih nama BPR', style: TextStyle(fontSize: 14, color: Colors.grey.shade600))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected.namaBpr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text('BPR ID: ${selected.bprId}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/logo_medfo_agent.png', width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff0F3D2E)),
                    ),
                    const SizedBox(height: 8),
                    Text('Silakan login untuk melanjutkan', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildBprField(),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _userIdController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'User ID',
                              hintText: 'Masukkan User ID',
                              prefixIcon: const Icon(Icons.person, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            style: const TextStyle(fontSize: 14),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              hintText: 'Masukkan Password',
                              prefixIcon: const Icon(Icons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0F3D2E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    )
                                  : const Text('Masuk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _showLupaSandiDialog,
                        child: Text('Lupa Sandi ?', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Text('Versi 1.0.3', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Image.asset('assets/Logo_MTD_lurus.png', height: 30),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BprPickerSheet extends StatefulWidget {
  final List<BprProfile> profiles;
  final String? selectedBprId;

  const _BprPickerSheet({required this.profiles, required this.selectedBprId});

  @override
  State<_BprPickerSheet> createState() => _BprPickerSheetState();
}

class _BprPickerSheetState extends State<_BprPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<BprProfile> _filteredProfiles;

  @override
  void initState() {
    super.initState();
    _filteredProfiles = widget.profiles;
    _searchController.addListener(_filterProfiles);
  }

  void _filterProfiles() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredProfiles = widget.profiles;
        return;
      }

      _filteredProfiles = widget.profiles.where((profile) {
        return profile.namaBpr.toLowerCase().contains(query) ||
            profile.bprId.toLowerCase().contains(query) ||
            profile.alamat.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterProfiles)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: screenHeight * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pilih BPR',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0F3D2E)),
                      ),
                    ),
                    IconButton(tooltip: 'Tutup', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari nama BPR atau BPR ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(tooltip: 'Hapus pencarian', onPressed: _searchController.clear, icon: const Icon(Icons.clear)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  ),
                ),
              ),
              Expanded(
                child: _filteredProfiles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('BPR tidak ditemukan', textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: _filteredProfiles.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final profile = _filteredProfiles[index];
                          final selected = profile.bprId == widget.selectedBprId;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xff0F3D2E).withOpacity(0.10),
                              child: const Icon(Icons.account_balance, color: Color(0xff0F3D2E), size: 20),
                            ),
                            title: Text(profile.namaBpr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Text('BPR ID: ${profile.bprId}', style: const TextStyle(fontSize: 12)),
                                if (profile.alamat.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.alamat.replaceAll('\n', ' '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                            trailing: selected ? const Icon(Icons.check_circle, color: Color(0xff0F3D2E)) : const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, profile),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
