// lib/pages/login_page.dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/brand_logo.dart';
import 'aktivasi_page.dart';
import 'lupa_password_page.dart';
import 'main_menu_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final username = _usernameController.text.trim().toUpperCase();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showErrorDialog('Username tidak boleh kosong.');
      return;
    }
    if (password.isEmpty) {
      _showErrorDialog('Password tidak boleh kosong.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        _showErrorDialog(result.message);
        return;
      }

      final session = await _authService.getSessionData();
      final bprId = session['bpr_id']?.trim() ?? '';
      final userId = session['user_id']?.trim() ?? '';
      final nama = session['nama']?.trim() ?? '';

      if (bprId.isEmpty || userId.isEmpty) {
        await _authService.clearSession();
        if (!mounted) return;
        _showErrorDialog(
          'Login berhasil, tetapi data session tidak lengkap. Silakan login kembali.',
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainMenuPage(
            userName: nama.isNotEmpty
                ? nama
                : (result.user?.nama ?? userId),
            bprId: bprId,
            userId: userId,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showErrorDialog(
          'Gagal memproses login. Silakan coba kembali.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  Future<void> _openActivation() async {
    final username = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AktivasiPage()),
    );
    if (mounted && (username ?? '').isNotEmpty) {
      _usernameController.text = username!;
      _passwordController.clear();
    }
  }

  Future<void> _openForgotPassword() async {
    final username = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const LupaPasswordPage()),
    );
    if (mounted && (username ?? '').isNotEmpty) {
      _usernameController.text = username!;
      _passwordController.clear();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.canvas,
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
                    const BrandLogo(size: 104, ringWidth: 3),
                    const SizedBox(height: 28),
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.brand900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan login untuk melanjutkan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: BrandColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.brand900.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              hintText: 'Masukkan username',
                              prefixIcon: const Icon(Icons.person, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
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
                              hintText: 'Masukkan password',
                              prefixIcon: const Icon(Icons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient:
                                    _isLoading ? null : BrandGradients.button,
                                color:
                                    _isLoading ? Colors.grey.shade300 : null,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isLoading
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: BrandColors.brand900
                                              .withOpacity(0.28),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  _isLoading ? null : _openActivation,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BrandColors.brand900,
                                side: const BorderSide(
                                  color: BrandColors.brand700,
                                  width: 1.5,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Aktivasi Akun',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed:
                            _isLoading ? null : _openForgotPassword,
                        child: Text(
                          'Lupa Sandi?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16, bottom: 28),
            color: Colors.white,
            child: Column(
              children: [
                Image.asset('assets/Logo_MTD_lurus.png', height: 40),
                const SizedBox(height: 10),
                Text(
                  'Versi 1.0.6',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
