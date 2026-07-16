import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bpr_profile_model.dart';
import '../services/auth_service.dart';
import '../widgets/bpr_picker_field.dart';

class LupaPasswordPage extends StatefulWidget {
  const LupaPasswordPage({super.key});

  @override
  State<LupaPasswordPage> createState() => _LupaPasswordPageState();
}

class _LupaPasswordPageState extends State<LupaPasswordPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  BprProfile? _selectedBpr;
  String _challengeToken = '';
  String _verificationToken = '';
  int _step = 0;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _requestOtp() async {
    final bpr = _selectedBpr;
    if (bpr == null) {
      _showMessage('Lupa Sandi Gagal', 'Silakan pilih BPR terlebih dahulu.');
      return;
    }

    setState(() => _loading = true);
    final result = await _authService.requestForgotPasswordOtp(
      bprId: bpr.bprId,
      username: _usernameController.text,
      phone: _phoneController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.isSuccess) {
      _showMessage('Lupa Sandi Gagal', result.message);
      return;
    }

    if (result.challengeToken.isEmpty) {
      _showMessage(
        'Lupa Sandi Gagal',
        'Challenge token tidak tersedia pada response server.',
      );
      return;
    }

    setState(() {
      _challengeToken = result.challengeToken;
      _otpController.clear();
      _step = 1;
    });
    _showSnack(result.message);
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showMessage('OTP Tidak Valid', 'Masukkan 6 digit kode OTP.');
      return;
    }

    setState(() => _loading = true);
    final result = await _authService.verifyForgotPasswordOtp(
      challengeToken: _challengeToken,
      otp: _otpController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.isSuccess) {
      _showMessage('Verifikasi Gagal', result.message);
      return;
    }

    if (result.verificationToken.isEmpty) {
      _showMessage(
        'Verifikasi Gagal',
        'Verification token tidak tersedia pada response server.',
      );
      return;
    }

    setState(() {
      _verificationToken = result.verificationToken;
      _step = 2;
    });
  }

  Future<void> _resetPassword() async {
    setState(() => _loading = true);
    final result = await _authService.resetForgotPassword(
      verificationToken: _verificationToken,
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.isSuccess) {
      _showMessage('Reset Password Gagal', result.message);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Password Berhasil Diubah', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          result.message.isEmpty
              ? 'Silakan login kembali menggunakan password baru.'
              : result.message,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0F3D2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ke Login'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.pop(
        context,
        _usernameController.text.trim().toUpperCase(),
      );
    }
  }

  void _showMessage(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildStepHeader() {
    const labels = ['Data Akun', 'Verifikasi OTP', 'Password Baru'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= _step;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: active
                    ? const Color(0xff0F3D2E)
                    : Colors.grey.shade300,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active
                      ? const Color(0xff0F3D2E)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildIdentityStep() {
    return Column(
      children: [
        BprPickerField(
          enabled: !_loading,
          initialBprId: _selectedBpr?.bprId,
          onChanged: (value) => _selectedBpr = value,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          enabled: !_loading,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'Masukkan username petugas',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          enabled: !_loading,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
          ],
          decoration: InputDecoration(
            labelText: 'Nomor HP',
            hintText: 'Nomor HP yang terdaftar',
            prefixIcon: const Icon(Icons.phone_android),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton('Kirim OTP', _requestOtp),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const Icon(
          Icons.sms_outlined,
          size: 54,
          color: Color(0xff0F3D2E),
        ),
        const SizedBox(height: 12),
        Text(
          'Masukkan kode OTP yang dikirim ke nomor ${_phoneController.text.trim()}.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          enabled: !_loading,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            labelText: 'Kode OTP',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton('Verifikasi OTP', _verifyOtp),
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  setState(() {
                    _step = 0;
                    _challengeToken = '';
                    _otpController.clear();
                  });
                },
          child: const Text('Ubah data / kirim ulang OTP'),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        _passwordField(
          controller: _passwordController,
          label: 'Password Baru',
          obscure: _obscurePassword,
          onToggle: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        const SizedBox(height: 16),
        _passwordField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password Baru',
          obscure: _obscureConfirm,
          onToggle: () {
            setState(() => _obscureConfirm = !_obscureConfirm);
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Password minimal 8 karakter.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton('Simpan Password Baru', _resetPassword),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      enabled: !_loading,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: _loading ? null : onToggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label, Future<void> Function() onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading
            ? null
            : () {
                onPressed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff0F3D2E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Lupa Sandi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff0F3D2E),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildStepHeader(),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _step == 0
                    ? _buildIdentityStep()
                    : (_step == 1
                        ? _buildOtpStep()
                        : _buildPasswordStep()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
