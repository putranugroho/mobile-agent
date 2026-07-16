// lib/widgets/brand_logo.dart
//
// Elemen identitas visual bersama untuk aplikasi Mobile Agent.
//
// Masalah yang diperbaiki: logo `logo_medfo_agent.png` adalah PNG dengan
// sudut TRANSPARAN (badge kotak-membulat lime di tengah). Kalau di-clip
// jadi lingkaran dengan BoxFit.cover, sudut transparannya jadi terlihat
// sebagai "baji putih" di antara logo dan bingkai — itulah kesan "logo
// nyempil, keliatan sisi putihnya".
//
// Solusi: sajikan logo sebagai SQUIRCLE (mengikuti bentuk asli badge),
// dengan isi bingkai berwarna senada logo (lime) sehingga sudut transparan
// menyatu — bukan putih. Cincin tipis emas→hijau memberi kesan "cap resmi"
// yang elegan tanpa mengubah bentuk atau tata letak logo.
import 'package:flutter/material.dart';

class BrandColors {
  BrandColors._();

  // Hijau institusi (jangkar identitas — tidak diubah).
  static const Color brand900 = Color(0xFF0F3D2E);
  static const Color brand800 = Color(0xFF124A38);
  static const Color brand700 = Color(0xFF1B5C43);
  static const Color brand500 = Color(0xFF2E8B62);
  static const Color brand300 = Color(0xFF8FC3A8);

  // Aksen emas-perunggu (motif cincin "cap resmi").
  static const Color gold600 = Color(0xFFB8873B);
  static const Color gold400 = Color(0xFFD9B979);
  static const Color gold100 = Color(0xFFF3E6CB);

  // Warna badge logo (lime) — dipakai sebagai isi bingkai squircle supaya
  // sudut transparan logo tidak tampak sebagai baji putih.
  static const Color logoLime = Color(0xFFC8F03C);

  // Permukaan & teks.
  static const Color canvas = Color(0xFFF3F7F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEAF3EE);
  static const Color border = Color(0xFFE1E8E2);
  static const Color ink = Color(0xFF12241C);
  static const Color inkSoft = Color(0xFF5B6B62);
  static const Color inkFaint = Color(0xFF8B9A92);

  static const Color danger = Color(0xFFB0453A);
  static const Color dangerDark = Color(0xFF8F3229);
}

class BrandGradients {
  BrandGradients._();

  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.brand800, BrandColors.brand900],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.brand700, BrandColors.brand900],
  );

  static const LinearGradient button = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.brand700, BrandColors.brand900],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandColors.danger, BrandColors.dangerDark],
  );

  /// Cincin "cap resmi" emas→hijau.
  static const SweepGradient seal = SweepGradient(
    colors: [
      BrandColors.gold600,
      BrandColors.gold400,
      BrandColors.brand500,
      BrandColors.gold600,
    ],
    stops: [0.0, 0.12, 0.55, 1.0],
    transform: GradientRotation(-0.7),
  );
}

/// Logo utama medfo dalam bingkai squircle dengan cincin emas→hijau.
///
/// [size] adalah dimensi luar total (termasuk cincin). Isi bingkai diberi
/// warna lime senada logo sehingga tidak ada baji putih.
class BrandLogo extends StatelessWidget {
  final double size;
  final double ringWidth;
  final bool showRing;
  final Color innerColor;

  const BrandLogo({
    super.key,
    this.size = 96,
    this.ringWidth = 3,
    this.showRing = true,
    this.innerColor = BrandColors.logoLime,
  });

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(size * 0.30);
    final innerRadius = BorderRadius.circular(size * 0.30 - ringWidth);

    final inner = ClipRRect(
      borderRadius: innerRadius,
      child: Container(
        color: innerColor,
        padding: EdgeInsets.all(size * 0.06),
        child: Image.asset(
          'assets/logo_medfo_agent_trimmed.png',
          fit: BoxFit.contain,
        ),
      ),
    );

    if (!showRing) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(borderRadius: outerRadius, child: inner),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        gradient: BrandGradients.seal,
        boxShadow: [
          BoxShadow(
            color: BrandColors.brand900.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: inner,
    );
  }
}

/// Avatar berinisial dalam cincin emas→hijau — dipakai di header & profil.
class SealInitials extends StatelessWidget {
  final String name;
  final double size;
  final double ringWidth;
  final double fontSize;
  final Color background;

  const SealInitials({
    super.key,
    required this.name,
    this.size = 56,
    this.ringWidth = 2.4,
    this.fontSize = 20,
    this.background = BrandColors.brand900,
  });

  static String initialsOf(String value, {int maxChars = 2}) {
    final parts =
        value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= maxChars ? maxChars : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: BrandGradients.seal,
      ),
      child: Container(
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          initialsOf(name),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
