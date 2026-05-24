import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_provider.dart';
import 'health_service.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(healthSummaryProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.health_and_safety_rounded, color: Color(0xFF374151), size: 48),
              const SizedBox(height: 12),
              const Text('Health data unavailable',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Make sure StepUp has Health app access\nin Settings → Health → Data Access',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  textAlign: TextAlign.center),
            ]),
          ),
          data: (s) => _HealthBody(summary: s),
        ),
      ),
    );
  }
}

class _HealthBody extends StatelessWidget {
  final HealthSummary summary;
  const _HealthBody({required this.summary});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Main activity ring card
              _ActivityRingCard(summary: summary),
              const SizedBox(height: 12),

              // Stats grid
              _StatsGrid(summary: summary),
              const SizedBox(height: 16),

              // Heart rate
              if (summary.heartRate != null) ...[
                _HeartRateCard(hr: summary.heartRate!),
                const SizedBox(height: 16),
              ],

              // Hourly step chart
              _SectionLabel('HOURLY STEPS'),
              const SizedBox(height: 8),
              _HourlyChart(buckets: summary.hourlySteps),
              const SizedBox(height: 16),

              // Workout sessions
              if (summary.workouts.isNotEmpty) ...[
                _SectionLabel('WORKOUTS & SESSIONS  •  ${summary.workouts.length}'),
                const SizedBox(height: 8),
                ...summary.workouts.reversed.map((w) => _WorkoutCard(w)),
              ] else ...[
                _SectionLabel('WORKOUTS & SESSIONS'),
                const SizedBox(height: 8),
                _EmptyWorkouts(),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Today', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          Text('Health & Activity', style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _ActivityRingCard extends StatelessWidget {
  final HealthSummary summary;
  const _ActivityRingCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final stepGoal = 10000;
    final calGoal = 500.0;
    final minGoal = 30;

    final stepPct = (summary.steps / stepGoal).clamp(0.0, 1.0);
    final calPct  = (summary.activeCalories / calGoal).clamp(0.0, 1.0);
    final minPct  = (summary.activeMinutes / minGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        // Rings
        SizedBox(
          width: 90, height: 90,
          child: Stack(alignment: Alignment.center, children: [
            _Ring(progress: stepPct, color: const Color(0xFF6366F1), strokeWidth: 9, radius: 44),
            _Ring(progress: calPct,  color: const Color(0xFF34D399), strokeWidth: 7, radius: 33),
            _Ring(progress: minPct,  color: const Color(0xFFF97316), strokeWidth: 6, radius: 23),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _RingLegend(color: const Color(0xFF6366F1), label: 'Move',
                value: '${_fmt(summary.steps)} steps', pct: stepPct),
            const SizedBox(height: 8),
            _RingLegend(color: const Color(0xFF34D399), label: 'Active Cal',
                value: '${summary.activeCalories.toInt()} kcal', pct: calPct),
            const SizedBox(height: 8),
            _RingLegend(color: const Color(0xFFF97316), label: 'Exercise',
                value: '${summary.activeMinutes} min', pct: minPct),
          ]),
        ),
      ]),
    );
  }

  String _fmt(int n) => n >= 1000
      ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'
      : '$n';
}

class _Ring extends StatelessWidget {
  final double progress, strokeWidth, radius;
  final Color color;
  const _Ring({required this.progress, required this.color,
      required this.strokeWidth, required this.radius});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(radius * 2, radius * 2),
    painter: _RingPainter(progress: progress, color: color, strokeWidth: strokeWidth),
  );
}

class _RingPainter extends CustomPainter {
  final double progress, strokeWidth;
  final Color color;
  const _RingPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label, value;
  final double pct;
  const _RingLegend({required this.color, required this.label,
      required this.value, required this.pct});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B7280),
          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      Text(value, style: TextStyle(color: color,
          fontSize: 13, fontWeight: FontWeight.w800)),
    ]),
    const Spacer(),
    Text('${(pct * 100).toInt()}%',
        style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w700)),
  ]);
}

class _StatsGrid extends StatelessWidget {
  final HealthSummary summary;
  const _StatsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _StatTile(icon: Icons.directions_walk_rounded, label: 'Distance',
            value: '${summary.distanceKm.toStringAsFixed(2)} km',
            color: const Color(0xFF6366F1)),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.local_fire_department_rounded, label: 'Total Cal',
            value: '${summary.totalCalories.toInt()} kcal',
            color: const Color(0xFFEF4444)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _StatTile(icon: Icons.stairs_rounded, label: 'Floors',
            value: '${summary.floorsClimbed}',
            color: const Color(0xFFFBBF24)),
        const SizedBox(width: 10),
        _StatTile(icon: Icons.airline_seat_recline_normal_rounded, label: 'Stand',
            value: '${summary.standMinutes} min',
            color: const Color(0xFF34D399)),
      ]),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatTile({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280),
              fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
          Text(value, style: TextStyle(color: color,
              fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
      ]),
    ),
  );
}

class _HeartRateCard extends StatelessWidget {
  final HeartRateSummary hr;
  const _HeartRateCard({required this.hr});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 16),
        const SizedBox(width: 6),
        const Text('HEART RATE', style: TextStyle(color: Color(0xFFEF4444),
            fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        const Spacer(),
        if (hr.resting > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${hr.resting} bpm resting',
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w700)),
          ),
      ]),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _HRStat('MIN', '${hr.min}', 'bpm'),
        _HRDivider(),
        _HRStat('AVG', '${hr.avg}', 'bpm'),
        _HRDivider(),
        _HRStat('MAX', '${hr.max}', 'bpm'),
      ]),
      const SizedBox(height: 14),
      // Mini HR sparkline
      if (hr.points.length > 2) _HRSparkline(points: hr.points),
    ]),
  );
}

class _HRStat extends StatelessWidget {
  final String label, value, unit;
  const _HRStat(this.label, this.value, this.unit);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Color(0xFF6B7280),
        fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    const SizedBox(height: 2),
    RichText(text: TextSpan(children: [
      TextSpan(text: value, style: const TextStyle(color: Color(0xFFEF4444),
          fontSize: 22, fontWeight: FontWeight.w900)),
      TextSpan(text: ' $unit', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
    ])),
  ]);
}

class _HRDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 36, color: const Color(0xFF1F2937));
}

class _HRSparkline extends StatelessWidget {
  final List<HeartRatePoint> points;
  const _HRSparkline({required this.points});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: CustomPaint(
      painter: _SparklinePainter(points: points),
      size: const Size(double.infinity, 36),
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  final List<HeartRatePoint> points;
  const _SparklinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final bpms = points.map((p) => p.bpm.toDouble()).toList();
    final minV = bpms.reduce((a, b) => a < b ? a : b);
    final maxV = bpms.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).clamp(1.0, double.infinity);

    final paint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < bpms.length; i++) {
      final x = i / (bpms.length - 1) * size.width;
      final y = size.height - (bpms[i] - minV) / range * size.height;
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => false;
}

class _HourlyChart extends StatelessWidget {
  final List<HourlyBucket> buckets;
  const _HourlyChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxSteps = buckets.map((b) => b.steps).reduce((a, b) => a > b ? a : b);
    final peak = maxSteps.clamp(1, double.infinity);
    final now = DateTime.now().hour;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${buckets.map((b) => b.steps).reduce((a, b) => a + b)} steps total',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
          const Spacer(),
          if (maxSteps > 0)
            Text('peak ${_fmtHour(buckets.indexOf(buckets.reduce((a, b) => a.steps > b.steps ? a : b)))}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets.map((b) {
              final isPast = b.hour <= now;
              final isCurrent = b.hour == now;
              final height = b.steps == 0 ? 2.0 : (b.steps / peak) * 56 + 4;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: isPast ? height : 2,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF6366F1)
                              : isPast
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                                  : const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('12a', style: const TextStyle(color: Color(0xFF4B5563), fontSize: 8)),
          Text('6a',  style: const TextStyle(color: Color(0xFF4B5563), fontSize: 8)),
          Text('12p', style: const TextStyle(color: Color(0xFF4B5563), fontSize: 8)),
          Text('6p',  style: const TextStyle(color: Color(0xFF4B5563), fontSize: 8)),
          Text('11p', style: const TextStyle(color: Color(0xFF4B5563), fontSize: 8)),
        ]),
      ]),
    );
  }

  String _fmtHour(int h) {
    if (h == 0) return '12a';
    if (h < 12) return '${h}a';
    if (h == 12) return '12p';
    return '${h - 12}p';
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutSession workout;
  const _WorkoutCard(this.workout);

  @override
  Widget build(BuildContext context) {
    final start = workout.start;
    final timeStr = '${_fmtTime(start)} – ${_fmtTime(workout.end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        // Emoji icon
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(workout.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(workout.label, style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(timeStr, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ]),
        ),

        // Stats
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(workout.durationLabel,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (workout.distanceKm > 0.01) ...[
              Text('${workout.distanceKm.toStringAsFixed(2)}km',
                  style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
            ],
            if (workout.calories > 0)
              Text('${workout.calories.toInt()} kcal',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ]),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'pm' : 'am';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m$period';
  }
}

class _EmptyWorkouts extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🏋️', style: TextStyle(fontSize: 32)),
        SizedBox(height: 8),
        Text('No workouts logged today',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        SizedBox(height: 4),
        Text('Workouts from Apple Health will appear here',
            style: TextStyle(color: Color(0xFF374151), fontSize: 10)),
      ]),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: Color(0xFF4B5563), fontSize: 9,
        fontWeight: FontWeight.w800, letterSpacing: 0.8),
  );
}
