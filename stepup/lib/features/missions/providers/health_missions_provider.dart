import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../steps/step_sync_service.dart';

class HealthMission {
  final String id, title, activity, unit;
  final double current, target;
  final int coinReward, xpReward;

  const HealthMission({
    required this.id,
    required this.title,
    required this.activity,
    required this.unit,
    required this.current,
    required this.target,
    required this.coinReward,
    required this.xpReward,
  });

  bool get completed => current >= target;
  double get progressPct => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  String get progressLabel {
    final cur = _fmt(current, unit);
    final tgt = _fmt(target, unit);
    return completed ? '$cur / $tgt · done' : '$cur / $tgt';
  }

  static String _fmt(double v, String unit) {
    if (unit == 'steps') {
      return v >= 1000
          ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k'
          : v.toInt().toString();
    }
    if (unit == 'L') return v.toStringAsFixed(1);
    if (unit == 'hrs') return v.toStringAsFixed(1);
    if (unit == 'min') return v.toInt().toString();
    return v.toInt().toString();
  }
}

final healthMissionsProvider = FutureProvider<List<HealthMission>>((ref) async {
  final svc = StepSyncService.instance;
  final today = DateTime.now();

  final results = await Future.wait([
    svc.getDaySummary(today),
    svc.getSleepHoursForDate(today),
    svc.getWaterLitersForDate(today),
    svc.getWorkoutsForDate(today),
  ]);

  final summary = results[0] as HealthDaySummary;
  final sleepHrs = results[1] as double;
  final waterL = results[2] as double;
  final workouts = results[3] as List<HealthWorkout>;

  return [
    HealthMission(
      id: 'steps',
      title: 'Walk 8,000 steps',
      activity: 'walk',
      unit: 'steps',
      current: summary.steps.toDouble(),
      target: 8000,
      coinReward: 15,
      xpReward: 30,
    ),
    HealthMission(
      id: 'water',
      title: 'Drink 2.5L water',
      activity: 'droplet',
      unit: 'L',
      current: waterL,
      target: 2.5,
      coinReward: 10,
      xpReward: 25,
    ),
    HealthMission(
      id: 'sleep',
      title: 'Sleep 7+ hours',
      activity: 'moon',
      unit: 'hrs',
      current: sleepHrs,
      target: 7.0,
      coinReward: 15,
      xpReward: 25,
    ),
    HealthMission(
      id: 'active',
      title: '30 min active time',
      activity: 'yoga',
      unit: 'min',
      current: summary.activeMins.toDouble(),
      target: 30,
      coinReward: 10,
      xpReward: 20,
    ),
    HealthMission(
      id: 'workout',
      title: 'Log a workout',
      activity: 'gym',
      unit: 'workout',
      current: workouts.isNotEmpty ? 1 : 0,
      target: 1,
      coinReward: 20,
      xpReward: 30,
    ),
  ];
});
