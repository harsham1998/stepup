import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/water_provider.dart';
import '../../../features/steps/step_sync_service.dart';
import '../../../core/theme.dart';

const double _goalLiters = 2.5;
const double _logAmountLiters = 0.5;
const int _maxLogsPerDay = 5;
const int _cooldownMinutes = 60;

class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen> {
  Timer? _timer;
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _cooldownRemaining(List<WaterLog> logs) {
    if (logs.isEmpty) return Duration.zero;
    final last = logs.last.time;
    final elapsed = DateTime.now().difference(last);
    final remaining = Duration(minutes: _cooldownMinutes) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _log() async {
    if (_logging) return;
    setState(() => _logging = true);
    final success = await StepSyncService.instance.logWater(_logAmountLiters);
    if (success && mounted) {
      ref.invalidate(waterTodayProvider);
      ref.invalidate(waterHistoryProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged ${(_logAmountLiters * 1000).round()}ml 💧'),
          backgroundColor: AppTheme.voltLime,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _logging = false);
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(waterTodayProvider);
    final historyAsync = ref.watch(waterHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: todayAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
          data: (logs) {
            final totalL = logs.fold(0.0, (s, l) => s + l.liters);
            final pct = (totalL / _goalLiters).clamp(0.0, 1.0);
            final logsToday = logs.length;
            final goalReached = logsToday >= _maxLogsPerDay;
            final cooldown = _cooldownRemaining(logs);
            final canLog = !goalReached && cooldown == Duration.zero;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // Header
                Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Text('Water', style: AppTheme.bigNum(20)),
                  const Spacer(),
                  const SizedBox(width: 22),
                ]),
                const SizedBox(height: 28),

                // Progress ring
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 14,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(
                            goalReached ? AppTheme.voltLime : const Color(0xFF38BDF8),
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.water_drop_rounded,
                            color: goalReached ? AppTheme.voltLime : const Color(0xFF38BDF8),
                            size: 28),
                        const SizedBox(height: 4),
                        Text(
                          '${totalL.toStringAsFixed(1)}L',
                          style: AppTheme.bigNum(40),
                        ),
                        Text(
                          'of ${_goalLiters.toStringAsFixed(1)}L',
                          style: AppTheme.label(13, color: AppTheme.ink2),
                        ),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // 5 dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_maxLogsPerDay, (i) {
                    final filled = i < logsToday;
                    return Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: filled
                              ? const Color(0xFF38BDF8)
                              : Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: filled
                          ? const Icon(Icons.water_drop_rounded,
                              color: Color(0xFF38BDF8), size: 14)
                          : null,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    goalReached
                        ? '🎉 Goal reached! All 5 logged today'
                        : '$logsToday of $_maxLogsPerDay logged · ${_maxLogsPerDay - logsToday} more to complete',
                    style: AppTheme.label(12, color: AppTheme.ink2),
                  ),
                ),
                const SizedBox(height: 24),

                // Log button
                if (!goalReached) ...[
                  if (cooldown > Duration.zero)
                    Center(
                      child: Text(
                        'Next log in ${cooldown.inMinutes}m ${cooldown.inSeconds % 60}s',
                        style: AppTheme.label(13, color: AppTheme.ink2),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        'Ready to log!',
                        style: AppTheme.label(13, color: const Color(0xFF38BDF8)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canLog && !_logging ? _log : null,
                      icon: _logging
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg),
                            )
                          : const Icon(Icons.water_drop_rounded, size: 18),
                      label: Text(
                        goalReached ? 'Goal reached!' : 'Log 500ml',
                        style: AppTheme.label(15, color: AppTheme.bg)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canLog
                            ? const Color(0xFF38BDF8)
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: AppTheme.bg,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                if (goalReached) const SizedBox(height: 28),

                // Today's timeline
                if (logs.isNotEmpty) ...[
                  _SectionLabel('Today\'s logs'),
                  const SizedBox(height: 10),
                  ...logs.reversed.map((log) => _LogTile(log: log)),
                  const SizedBox(height: 28),
                ],

                // Analytics
                _SectionLabel('Last 14 days'),
                const SizedBox(height: 16),
                historyAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.voltLime)),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (history) => _HistoryChart(history: history),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTheme.label(11, color: AppTheme.ink2)
            .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
      );
}

class _LogTile extends StatelessWidget {
  final WaterLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final h = log.time.hour;
    final m = log.time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = (h % 12 == 0 ? 12 : h % 12);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.water_drop_rounded,
              color: Color(0xFF38BDF8), size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${(log.liters * 1000).round()} ml',
            style: AppTheme.label(14, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '$hour:$m $period',
            style: AppTheme.label(11, color: AppTheme.ink2),
          ),
        ]),
        const Spacer(),
        Text(
          '+${log.liters.toStringAsFixed(1)}L',
          style: AppTheme.label(13, color: const Color(0xFF38BDF8))
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<double> history;
  const _HistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final maxVal = history.fold(0.0, (m, v) => v > m ? v : m);
    final chartMax = maxVal < _goalLiters ? _goalLiters + 0.5 : maxVal + 0.5;
    const barH = 120.0;

    final daysHit = history.where((v) => v >= _goalLiters).length;
    final avg = history.isEmpty ? 0.0
        : history.fold(0.0, (s, v) => s + v) / history.length;
    final best = history.fold(0.0, (m, v) => v > m ? v : m);

    final now = DateTime.now();
    final dayLabels = List.generate(14, (i) {
      final date = now.subtract(Duration(days: 13 - i));
      const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return names[date.weekday - 1];
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Bar chart
      SizedBox(
        height: barH + 24,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(history.length, (i) {
            final v = history[i];
            final h = v == 0 ? 2.0 : (v / chartMax * barH).clamp(2.0, barH);
            final isGoal = v >= _goalLiters;
            final isToday = i == history.length - 1;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isGoal
                          ? const Color(0xFF38BDF8).withValues(alpha: isToday ? 1.0 : 0.6)
                          : Colors.white.withValues(alpha: isToday ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dayLabels[i],
                    style: AppTheme.label(9,
                        color: isToday ? Colors.white : AppTheme.ink3),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 20),
      // Stats row
      Row(children: [
        _StatBox(label: '14-day avg', value: '${avg.toStringAsFixed(1)}L'),
        const SizedBox(width: 10),
        _StatBox(label: 'Best day', value: '${best.toStringAsFixed(1)}L'),
        const SizedBox(width: 10),
        _StatBox(label: 'Goal days', value: '$daysHit / 14'),
      ]),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTheme.label(10, color: AppTheme.ink2)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTheme.label(15, color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
