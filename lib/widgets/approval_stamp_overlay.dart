// lib/widgets/approval_stamp_overlay.dart
//
// Karena inti aplikasi ini adalah memberi keputusan resmi atas suatu
// pengajuan, momen "Setuju" diberi satu animasi kecil yang istimewa: cincin
// emas yang "digambar" lalu tanda centang hijau — seperti cap persetujuan.
// Murni dekoratif; tidak mengubah alur/logika persetujuan sama sekali.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ApprovalStampOverlay extends StatefulWidget {
  const ApprovalStampOverlay({super.key});

  @override
  State<ApprovalStampOverlay> createState() => _ApprovalStampOverlayState();
}

class _ApprovalStampOverlayState extends State<ApprovalStampOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..forward();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand900.withOpacity(0.10),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: const Size(148, 148),
              painter: _StampPainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  final double progress; // 0..1

  _StampPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;

    final settle = Curves.easeOutCubic.transform(progress.clamp(0, 1));
    final scale = 1.0 + (1 - settle) * 1.0;
    final rotation = (1 - settle) * -0.17;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // Denyut cincin tipis yang memudar keluar (efek "pulse").
    if (progress < 0.75) {
      final pulseT = (progress / 0.75).clamp(0.0, 1.0);
      final pulsePaint = Paint()
        ..color = AppColors.gold600.withOpacity((1 - pulseT) * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius * (0.6 + pulseT * 1.05), pulsePaint);
    }

    // Cincin emas "digambar" dari 0 ke 100%.
    final ringT = (progress / 0.55).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = AppColors.gold600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ringT,
      false,
      ringPaint,
    );

    // Tanda centang hijau menyusul setelah cincin selesai.
    final checkT = ((progress - 0.5) / 0.35).clamp(0.0, 1.0);
    if (checkT > 0) {
      final path = Path()
        ..moveTo(center.dx - radius * 0.42, center.dy + radius * 0.02)
        ..lineTo(center.dx - radius * 0.10, center.dy + radius * 0.32)
        ..lineTo(center.dx + radius * 0.46, center.dy - radius * 0.34);

      final metric = path.computeMetrics().first;
      final extracted = metric.extractPath(0, metric.length * checkT);
      final checkPaint = Paint()
        ..color = AppColors.brand700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(extracted, checkPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StampPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Tampilkan overlay cap persetujuan lalu tertutup otomatis. Panggil dengan
/// `await showApprovalStamp(context);` tepat setelah status berhasil
/// diubah menjadi "Disetujui".
Future<void> showApprovalStamp(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, anim, secondaryAnim) => const ApprovalStampOverlay(),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}