// lib/widgets/gradient_button.dart
//
// Tombol aksi utama bergradasi (mis. "Masuk", "Setuju", "Simpan Password").
// Dipakai menggantikan ElevatedButton polos di titik-titik keputusan
// penting agar terasa lebih "niat" tanpa mengubah posisi/alur tombol.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool loading;
  final double height;
  final Color shadowTint;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.gradient = AppGradients.primary,
    this.loading = false,
    this.height = 50,
    this.shadowTint = AppColors.brand900,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || loading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: disabled ? null : AppShadows.button(shadowTint),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: disabled ? null : onPressed,
            child: Opacity(
              opacity: (onPressed == null && !loading) ? 0.5 : 1,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: AppText.bodyStyle(size: 14, weight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}