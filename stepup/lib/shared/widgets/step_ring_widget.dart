import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme.dart';

class StepRingWidget extends StatelessWidget {
  final int currentSteps, goalSteps;
  final double size;

  const StepRingWidget({
    required this.currentSteps, required this.goalSteps,
    this.size = 80, super.key,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentSteps / goalSteps).clamp(0.0, 1.0);
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
        child: Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = (size.width / 2) - 6;
    final trackPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.15)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF6366F1), Color(0xFFA78BFA)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false, fillPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
