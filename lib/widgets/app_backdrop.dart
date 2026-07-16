// lib/widgets/app_backdrop.dart
//
// Latar radial-glow lembut (emas di kanan-atas, hijau di kiri-bawah) yang
// meniru aksen dekoratif pada konsep redesain — dipakai di belakang layar
// Masuk supaya kesan pertama terasa lebih hidup, tanpa mengubah struktur
// konten di atasnya.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.canvas)),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.95, -0.9),
                  radius: 1.1,
                  colors: [AppColors.gold600.withOpacity(0.12), AppColors.gold600.withOpacity(0)],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.95, 0.95),
                  radius: 1.0,
                  colors: [AppColors.brand700.withOpacity(0.10), AppColors.brand700.withOpacity(0)],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}