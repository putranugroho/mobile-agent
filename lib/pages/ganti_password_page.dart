// lib/pages/ganti_password_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_button.dart';

class GantiPasswordPage extends StatefulWidget {
  final String bprId;
  final String userId;

  const GantiPasswordPage({
    super.key,
    required this.bprId,
    required this.userId,
  });

  @override
  State<GantiPasswordPage> createState() => _GantiPasswordPageState();
}

class _GantiPasswordPageState extends State<GantiPasswordPage> {
  final _oldPassCtrl     = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  final AuthService _authService = AuthService();

  Future<void> _submit() async {
    final oldPass     = _oldPassCtrl.text;
    final newPass     = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showDialog('Gagal', 'Semua kolom harus diisi');
      return;
    }
    if (newPass.length < 6) {
      _showDialog('Gagal', 'Password baru minimal 6 karakter');
      return;
    }
    if (newPass != confirmPass) {
      _showDialog('Gagal', 'Password baru dan konfirmasi tidak cocok');
      return;
    }
    if (newPass == oldPass) {
      _showDialog('Gagal', 'Password baru tidak boleh sama dengan password lama');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.changePassword(
        bprId:       widget.bprId,
        userId:      widget.userId,
        oldPassword: oldPass,
        newPassword: newPass,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        _showDialog('Berhasil', result.message, isSuccess: true);
      } else {
        _showDialog('Gagal', result.message);
      }
    } catch (_) {
      if (mounted) _showDialog('Gagal', 'Gagal terhubung ke server.\nPeriksa koneksi Anda.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
              color: isSuccess ? AppColors.approvedFg : AppColors.danger,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message, style: AppText.bodyStyle(size: 13, color: AppColors.inkSoft)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? AppColors.brand900 : AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      obscureText: obscure,
      style: AppText.bodyStyle(size: 14, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
          onPressed: onToggle,
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

            // Info user
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppGradients.header,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    widget.userId,
                    style: AppText.monoStyle(size: 13, weight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form
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
                    onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _newPassCtrl,
                    label: 'Password Baru',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _confirmPassCtrl,
                    label: 'Konfirmasi Password Baru',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
              'Password minimal 6 karakter',
              style: AppText.bodyStyle(size: 11, weight: FontWeight.w500, color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}
