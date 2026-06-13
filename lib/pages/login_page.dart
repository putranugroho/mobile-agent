// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_menu_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final String _bprId = '609999';
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    if (_userIdController.text.trim().isEmpty) {
      _showErrorDialog('User ID tidak boleh kosong');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Password tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        bprId: _bprId,
        userId: _userIdController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final session = await _authService.getSessionData();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainMenuPage(
              userName: session['nama'] ?? result.user?.nama ?? '',
              bprId: session['bpr_id'] ?? _bprId,
              userId: session['user_id'] ?? _userIdController.text.trim().toUpperCase(),
            ),
          ),
        );
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Gagal terhubung ke server.\nPeriksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
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
    showDialog(
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
                    // Logo
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
                    Text(
                      'Silakan login untuk melanjutkan',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 40),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // User ID
                          TextField(
                            controller: _userIdController,
                            decoration: InputDecoration(
                              labelText: 'User ID',
                              hintText: 'Masukkan User ID',
                              prefixIcon: const Icon(Icons.person, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            style: const TextStyle(fontSize: 14),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              hintText: 'Masukkan Password',
                              prefixIcon: const Icon(Icons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 24),

                          // Tombol Login
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Masuk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _showLupaSandiDialog,
                        child: Text('Lupa Sandi ?', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Text('Versi 1.0.1', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Image.asset(
                  'assets/Logo_MTD_lurus.png',
                  height: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
