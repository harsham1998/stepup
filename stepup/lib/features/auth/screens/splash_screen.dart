import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final isLoggedIn = ref.read(isLoggedInProvider);
      if (isLoggedIn) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) context.go('/home');
        });
      }
    });
  }

  void _onTap() {
    final isLoggedIn = ref.read(isLoggedInProvider);
    context.go(isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(),
                // Logo mark with arrow
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(90, 90),
                        painter: _LogoPainter(),
                      ),
                      Text('↑', style: AppTheme.bigNum(38, color: AppTheme.voltLime)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // StepUp title
                RichText(
                  text: TextSpan(
                    style: AppTheme.bigNum(56),
                    children: const [
                      TextSpan(text: 'Step'),
                      TextSpan(
                        text: 'Up',
                        style: TextStyle(color: AppTheme.voltLime),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Walk · compete · cash in',
                  style: AppTheme.label(13, color: AppTheme.ink2),
                ),
                const Spacer(),
                Text(
                  'Tap anywhere to begin',
                  style: AppTheme.label(12, color: AppTheme.ink3),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'V 1.0  ·  India',
                  style: AppTheme.label(11, color: AppTheme.ink3),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    // Outer volt-lime circle
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppTheme.voltLime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner amber arc (bottom-left quarter)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.55),
      pi * 0.75,
      pi,
      false,
      Paint()
        ..color = AppTheme.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
