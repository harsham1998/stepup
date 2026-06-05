import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../profile/providers/body_vitals_provider.dart';
import '../../../shared/models/body_vitals.dart';

class BodyVitalsHomeWidget extends ConsumerWidget {
  const BodyVitalsHomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(bodyVitalsSummaryProvider);
    final historyAsync = ref.watch(bodyVitalsHistoryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.latest == null) return _EmptyCard(context: context);
        return _FilledCard(
          summary: summary,
          historyAsync: historyAsync,
          context: context,
        );
      },
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final BuildContext context;
  const _EmptyCard({required this.context});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/body-vitals'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monitor_weight_outlined,
                  color: AppTheme.voltLime, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Body Vitals',
                      style: GoogleFonts.bigShouldersDisplay(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Start tracking weight, BMI & more',
                      style: GoogleFonts.inter(
                          color: AppTheme.ink2, fontSize: 12)),
                ],
              ),
            ),
            Text('Log now →',
                style: GoogleFonts.inter(
                    color: AppTheme.voltLime,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Filled card ────────────────────────────────────────────────────────────────

class _FilledCard extends StatelessWidget {
  final BodyVitalsSummary summary;
  final AsyncValue<List<BodyVitalsEntry>> historyAsync;
  final BuildContext context;

  const _FilledCard({
    required this.summary,
    required this.historyAsync,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final latest = summary.latest!;
    final goalWeight = summary.goal?.goalWeightKg;

    return GestureDetector(
      onTap: () => context.push('/profile/body-vitals'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monitor_weight_outlined,
                      color: AppTheme.voltLime, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Body Vitals',
                    style: GoogleFonts.bigShouldersDisplay(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                if (summary.loggingStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: AppTheme.amber, size: 13),
                        const SizedBox(width: 3),
                        Text('${summary.loggingStreak}',
                            style: GoogleFonts.bigShouldersDisplay(
                                color: AppTheme.amber,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    color: AppTheme.ink3, size: 18),
              ],
            ),
            const SizedBox(height: 14),

            // ── Metrics row + sparkline ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Mini metric chips
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (latest.weightKg != null)
                        _MetricChip(
                          label: 'Weight',
                          value: '${latest.weightKg!.toStringAsFixed(1)} kg',
                          good: goalWeight == null
                              ? null
                              : latest.weightKg! <= goalWeight,
                        ),
                      if (latest.bmi != null)
                        _MetricChip(
                          label: 'BMI',
                          value: latest.bmi!.toStringAsFixed(1),
                          good: latest.bmi! < 25,
                        ),
                      if (latest.visceralFatLevel != null)
                        _MetricChip(
                          label: 'Visceral',
                          value: '${latest.visceralFatLevel}',
                          good: latest.visceralFatLevel! < 10,
                        ),
                      if (latest.musclePercentage != null)
                        _MetricChip(
                          label: 'Muscle',
                          value:
                              '${latest.musclePercentage!.toStringAsFixed(1)}%',
                          good: latest.musclePercentage! >= 30,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Sparkline
                historyAsync.when(
                  loading: () => const SizedBox(width: 72, height: 36),
                  error: (_, __) => const SizedBox(width: 72, height: 36),
                  data: (history) {
                    final weights = history
                        .where((e) => e.weightKg != null)
                        .map((e) => e.weightKg!)
                        .toList();
                    if (weights.length < 2) {
                      return const SizedBox(width: 72, height: 36);
                    }
                    return SizedBox(
                      width: 72,
                      height: 36,
                      child: CustomPaint(
                        painter: _SparklinePainter(
                          data: weights,
                          goal: goalWeight,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini metric chip ───────────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final bool? good;

  const _MetricChip({required this.label, required this.value, this.good});

  @override
  Widget build(BuildContext context) {
    final dotColor = good == null
        ? AppTheme.ink3
        : good!
            ? AppTheme.voltLime
            : AppTheme.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color: AppTheme.ink3,
                      fontSize: 9,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: GoogleFonts.bigShouldersDisplay(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sparkline painter ──────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final double? goal;

  const _SparklinePainter({required this.data, this.goal});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final range = (maxV - minV).clamp(0.5, double.infinity);

    double px(int i) => i / (data.length - 1) * size.width;
    double py(double v) =>
        size.height - ((v - minV) / range) * size.height * 0.85 - size.height * 0.075;

    // Goal line
    if (goal != null && goal! >= minV - range && goal! <= maxV + range) {
      final goalY = py(goal!.clamp(minV, maxV));
      final dashed = Paint()
        ..color = AppTheme.amber.withOpacity(0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (double x = 0; x < size.width; x += 6) {
        canvas.drawLine(
          Offset(x, goalY), Offset(math.min(x + 3, size.width), goalY), dashed);
      }
    }

    // Sparkline path
    final path = Path()..moveTo(px(0), py(data[0]));
    for (int i = 1; i < data.length; i++) {
      final cp1x = px(i - 1) + (px(i) - px(i - 1)) / 2;
      path.cubicTo(cp1x, py(data[i - 1]), cp1x, py(data[i]), px(i), py(data[i]));
    }

    final linePaint = Paint()
      ..color = AppTheme.voltLime
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // End dot
    canvas.drawCircle(
      Offset(px(data.length - 1), py(data.last)),
      3,
      Paint()..color = AppTheme.voltLime,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.goal != goal;
}
