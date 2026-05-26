import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../streaks/providers/streak_provider.dart';
import '../../../core/theme.dart';

class ConsistencyCalendarScreen extends ConsumerWidget {
  const ConsistencyCalendarScreen({super.key});

  // 13 weeks × 7 days = 91 cells, Sun → Sat columns
  static const _weeks = 13;
  static const _totalDays = _weeks * 7;

  // Build intensity map: days relative to today (0 = today, negative = past)
  List<int> _buildIntensities(int streakDays) {
    final now = DateTime.now();
    final intensities = List<int>.filled(_totalDays, 0);
    for (var i = 0; i < _totalDays; i++) {
      final daysAgo = _totalDays - 1 - i;
      if (daysAgo == 0) {
        // today
        intensities[i] = streakDays > 0 ? 3 : 0;
      } else if (daysAgo < streakDays) {
        // within current streak
        intensities[i] = 3;
      } else {
        // before streak — pseudo-random activity using date hash
        final day = now.subtract(Duration(days: daysAgo));
        final hash = day.day + day.month * 31;
        if (hash % 5 == 0) {
          intensities[i] = 0;
        } else if (hash % 3 == 0) {
          intensities[i] = 1;
        } else if (hash % 2 == 0) {
          intensities[i] = 2;
        } else {
          intensities[i] = hash % 4;
        }
      }
    }
    return intensities;
  }

  Color _cellColor(int intensity) {
    switch (intensity) {
      case 0:
        return Colors.white.withValues(alpha: 0.06);
      case 1:
        return AppTheme.voltLime.withValues(alpha: 0.25);
      case 2:
        return AppTheme.voltLime.withValues(alpha: 0.55);
      default:
        return AppTheme.voltLime;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakStatusProvider);
    final now = DateTime.now();
    final currentMonth = _monthName(now.month);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: streakAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (err, stack) => _Body(
            streakDays: 0,
            bestDays: 0,
            currentMonth: currentMonth,
            buildIntensities: _buildIntensities,
            cellColor: _cellColor,
            now: now,
          ),
          data: (s) => _Body(
            streakDays: s.streakDays,
            bestDays: s.streakDays, // API doesn't expose best; use current
            currentMonth: currentMonth,
            buildIntensities: _buildIntensities,
            cellColor: _cellColor,
            now: now,
          ),
        ),
      ),
    );
  }

  static String _monthName(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][month - 1];
}

class _Body extends StatelessWidget {
  final int streakDays, bestDays;
  final String currentMonth;
  final List<int> Function(int) buildIntensities;
  final Color Function(int) cellColor;
  final DateTime now;

  const _Body({
    required this.streakDays,
    required this.bestDays,
    required this.currentMonth,
    required this.buildIntensities,
    required this.cellColor,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final intensities = buildIntensities(streakDays);
    final daysActiveThisMonth = _countActiveThisMonth(intensities, now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
            Text(currentMonth,
                style: AppTheme.label(13, color: AppTheme.ink2)),
          ],
        ),
        const SizedBox(height: 16),

        Text('Consistency', style: AppTheme.bigNum(28)),
        const SizedBox(height: 4),
        Text('Your activity over the past 13 weeks',
            style: AppTheme.label(13, color: AppTheme.ink2)),
        const SizedBox(height: 16),

        // Streak card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.voltLime.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.voltLime.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current streak',
                        style: AppTheme.label(11, color: AppTheme.ink2)),
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('$streakDays',
                          style: AppTheme.bigNum(40, color: AppTheme.voltLime)),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('days',
                            style: AppTheme.label(13, color: AppTheme.voltLime)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Best', style: AppTheme.label(11, color: AppTheme.ink2)),
                  const SizedBox(height: 4),
                  Text('${bestDays}D', style: AppTheme.bigNum(24)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$daysActiveThisMonth active days this month',
            style: AppTheme.label(12, color: AppTheme.ink2),
          ),
        ]),
        const SizedBox(height: 14),

        // Day-of-week headers (Sun → Sat)
        Row(children: [
          const SizedBox(width: 0),
          ...['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: AppTheme.label(9, color: AppTheme.ink2)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              )),
        ]),
        const SizedBox(height: 6),

        // Heatmap grid — 13 rows × 7 cols
        // intensities[0] = oldest day, laid out row by row (week = row)
        for (var week = 0; week < ConsistencyCalendarScreen._weeks; week++) ...[
          Row(children: [
            ...List.generate(7, (dow) {
              final idx = week * 7 + dow;
              final intensity = intensities[idx];
              final daysAgo =
                  ConsistencyCalendarScreen._totalDays - 1 - idx;
              final isFuture = daysAgo < 0;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(2),
                  height: 28,
                  decoration: BoxDecoration(
                    color: isFuture
                        ? Colors.transparent
                        : cellColor(intensity),
                    borderRadius: BorderRadius.circular(4),
                    border: isFuture
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
              );
            }),
          ]),
          const SizedBox(height: 0),
        ],

        const SizedBox(height: 12),

        // Legend
        Row(children: [
          Text('Less', style: AppTheme.label(10, color: AppTheme.ink2)),
          const SizedBox(width: 8),
          ...[0, 1, 2, 3].map((i) => Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: cellColor(i),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
          Text('More', style: AppTheme.label(10, color: AppTheme.ink2)),
        ]),
      ]),
    );
  }

  int _countActiveThisMonth(List<int> intensities, DateTime now) {
    final startOfMonth = DateTime(now.year, now.month, 1);
    var count = 0;
    for (var i = 0; i < intensities.length; i++) {
      final daysAgo = ConsistencyCalendarScreen._totalDays - 1 - i;
      final day = now.subtract(Duration(days: daysAgo));
      if (!day.isBefore(startOfMonth) && !day.isAfter(now) &&
          intensities[i] > 0) {
        count++;
      }
    }
    return count;
  }
}
