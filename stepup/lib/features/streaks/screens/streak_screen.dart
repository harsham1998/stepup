import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/streak_provider.dart';
import '../providers/streak_calendar_provider.dart';
import '../../../shared/models/streak_calendar_day.dart';
import '../../../core/theme.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakStatusProvider);
    final calendarAsync = ref.watch(streakCalendarProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: streakAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => _StreakBody(streakDays: 12, shieldAvailable: true, calendarAsync: const AsyncValue.loading()),
          data: (streak) => _StreakBody(
            streakDays: streak.streakDays,
            shieldAvailable: streak.shieldAvailable,
            calendarAsync: calendarAsync,
          ),
        ),
      ),
    );
  }
}

class _StreakBody extends StatelessWidget {
  final int streakDays;
  final bool shieldAvailable;
  final AsyncValue<List<StreakCalendarDay>> calendarAsync;
  const _StreakBody({
    required this.streakDays,
    required this.shieldAvailable,
    required this.calendarAsync,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
            Text('Streak Protection',
                style: AppTheme.label(13, color: AppTheme.ink2)),
          ],
        ),
        const SizedBox(height: 16),

        // Shield hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                AppTheme.voltLime.withValues(alpha: 0.10),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            const Icon(Icons.shield_rounded,
                color: AppTheme.voltLime, size: 72),
            const SizedBox(height: 14),
            Text('$streakDays DAY STREAK',
                style: AppTheme.bigNum(28, color: AppTheme.voltLime)),
            const SizedBox(height: 4),
            Text(
              shieldAvailable
                  ? 'Protected · 1 of 1 shield available'
                  : 'No shield available this month',
              style: AppTheme.label(12, color: AppTheme.ink2),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('ACTIVITY CALENDAR',
            style: AppTheme.label(10, color: AppTheme.ink2)
                .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        calendarAsync.when(
          loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(color: AppTheme.voltLime, strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
          data: (days) => _StreakCalendar(days: days),
        ),
        const SizedBox(height: 14),

        // Monthly shield card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.voltLime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: AppTheme.voltLime, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Monthly shield',
                    style: AppTheme.label(13, color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Auto-saves your streak if you miss a day',
                    style: AppTheme.label(11, color: AppTheme.ink2)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('PRO',
                  style: AppTheme.label(10, color: AppTheme.amber)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        Text('Or revive a lost streak',
            style: AppTheme.label(10, color: AppTheme.ink2)
                .copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        // Revive card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.amber.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.amber.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppTheme.amber, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Revive streak',
                      style: AppTheme.label(13, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Available up to 2 days after losing',
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('₹15', style: AppTheme.bigNum(28, color: AppTheme.amber)),
                  Text('UPI / wallet', style: AppTheme.label(11, color: AppTheme.ink2)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text('Revive →',
                      style: AppTheme.label(13, color: AppTheme.amber)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // Info row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.ink3, size: 14),
            const SizedBox(width: 8),
            Text('Free users · Pro users · same revive cost',
                style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ),

        const SizedBox(height: 16),

        // CTA button
        GestureDetector(
          onTap: shieldAvailable
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shield used — streak protected!')),
                  )
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: shieldAvailable ? AppTheme.voltLime : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                shieldAvailable ? 'Use shield (1 left)' : 'No shield this month',
                style: AppTheme.label(14,
                        color: shieldAvailable ? AppTheme.bg : AppTheme.ink3)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StreakCalendar extends StatelessWidget {
  final List<StreakCalendarDay> days;
  const _StreakCalendar({required this.days});

  Color _colorFor(String status) {
    switch (status) {
      case 'full':
        return AppTheme.voltLime;
      case 'partial':
        return AppTheme.amber;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = days.length > 35 ? days.sublist(days.length - 35) : days;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: recent.map((day) {
        final hasActivity = day.status != 'none' && day.steps > 0;
        return Tooltip(
          message: '${day.date}\n${day.steps} steps',
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasActivity
                  ? _colorFor(day.status).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: day.streakCount > 0 && day.status == 'full'
                ? Center(
                    child: Text(
                      '${day.streakCount}',
                      style: const TextStyle(
                          color: AppTheme.bg,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
