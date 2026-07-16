// lib/pages/ganti_password_page.dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_button.dart';
import 'login_page.dart';

class GantiPasswordPage extends StatefulWidget {
  final String userId;

  const GantiPasswordPage({
    super.key,
    required this.userId,
  });

  @override
  State<GantiPasswordPage> createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends State<GantiPasswordPage> {
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final oldPassword = _oldPassCtrl.text;
    final newPassword = _newPassCtrl.text;
    final confirmPassword = _confirmPassCtrl.text;

    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showDialog('Gagal', 'Semua kolom harus diisi.');
      return;
    }
    if (newPassword.length < 8) {
      _showDialog('Gagal', 'Password baru minimal 8 karakter.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showDialog('Gagal', 'Password baru dan konfirmasi tidak cocok.');
      return;
    }
    if (newPassword == oldPassword) {
      _showDialog(
        'Gagal',
        'Password baru tidak boleh sama dengan password lama.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      _showDialog('Gagal', result.message);
      return;
    }

    _showDialog(
      'Berhasil',
      result.message.isEmpty
          ? 'Password berhasil diubah. Silakan login kembali.'
          : result.message,
      isSuccess: true,
    );
  }

  void _showDialog(
    String title,
    String message, {
    bool isSuccess = false,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: isSuccess ? AppColors.approvedFg : AppColors.danger,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          message,
          style: AppText.bodyStyle(size: 13, color: AppColors.inkSoft),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (isSuccess && mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSuccess ? AppColors.brand900 : AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: obscure,
      style: AppText.bodyStyle(size: 14, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 20,
          ),
          onPressed: _isLoading ? null : onToggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: const Text('Ganti Password'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.header,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.userId,
                    style: AppText.monoStyle(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  _buildField(
                    controller: _oldPassCtrl,
                    label: 'Password Lama',
                    obscure: _obscureOld,
                    onToggle: () {
                      setState(() => _obscureOld = !_obscureOld);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _newPassCtrl,
                    label: 'Password Baru',
                    obscure: _obscureNew,
                    onToggle: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _confirmPassCtrl,
                    label: 'Konfirmasi Password Baru',
                    obscure: _obscureConfirm,
                    onToggle: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Simpan Password',
                    loading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Password minimal 8 karakter',
              style: AppText.bodyStyle(
                size: 11,
                weight: FontWeight.w500,
                color: AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
