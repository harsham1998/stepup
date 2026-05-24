import 'package:health/health.dart';

final _readTypes = [
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_WALKING_RUNNING,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.BASAL_ENERGY_BURNED,
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.EXERCISE_TIME,
  HealthDataType.WORKOUT,
  HealthDataType.FLIGHTS_CLIMBED,
  HealthDataType.APPLE_STAND_TIME,
];

class HealthSummary {
  final int steps;
  final double distanceKm;
  final double activeCalories;
  final double totalCalories;
  final int activeMinutes;
  final int standMinutes;
  final int floorsClimbed;
  final HeartRateSummary? heartRate;
  final List<WorkoutSession> workouts;
  final List<HourlyBucket> hourlySteps;

  const HealthSummary({
    required this.steps,
    required this.distanceKm,
    required this.activeCalories,
    required this.totalCalories,
    required this.activeMinutes,
    required this.standMinutes,
    required this.floorsClimbed,
    this.heartRate,
    required this.workouts,
    required this.hourlySteps,
  });

  static HealthSummary empty() => const HealthSummary(
    steps: 0, distanceKm: 0, activeCalories: 0, totalCalories: 0,
    activeMinutes: 0, standMinutes: 0, floorsClimbed: 0,
    workouts: [], hourlySteps: [],
  );
}

class HeartRateSummary {
  final int avg, min, max, resting;
  final List<HeartRatePoint> points;
  const HeartRateSummary({
    required this.avg, required this.min, required this.max, required this.resting,
    required this.points,
  });
}

class HeartRatePoint {
  final DateTime time;
  final int bpm;
  const HeartRatePoint(this.time, this.bpm);
}

class WorkoutSession {
  final DateTime start, end;
  final HealthWorkoutActivityType activityType;
  final double distanceKm;
  final double calories;

  const WorkoutSession({
    required this.start,
    required this.end,
    required this.activityType,
    required this.distanceKm,
    required this.calories,
  });

  Duration get duration => end.difference(start);

  String get label {
    switch (activityType) {
      case HealthWorkoutActivityType.WALKING:                   return 'Walking';
      case HealthWorkoutActivityType.RUNNING:                   return 'Running';
      case HealthWorkoutActivityType.BIKING:                    return 'Cycling';
      case HealthWorkoutActivityType.HAND_CYCLING:              return 'Hand Cycling';
      case HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
      case HealthWorkoutActivityType.CROSS_TRAINING:            return 'Gym Workout';
      case HealthWorkoutActivityType.SOCCER:                    return 'Football';
      case HealthWorkoutActivityType.AMERICAN_FOOTBALL:         return 'American Football';
      case HealthWorkoutActivityType.AUSTRALIAN_FOOTBALL:       return 'Aussie Football';
      case HealthWorkoutActivityType.BASKETBALL:                return 'Basketball';
      case HealthWorkoutActivityType.CRICKET:                   return 'Cricket';
      case HealthWorkoutActivityType.BADMINTON:                 return 'Badminton';
      case HealthWorkoutActivityType.TENNIS:                    return 'Tennis';
      case HealthWorkoutActivityType.TABLE_TENNIS:              return 'Table Tennis';
      case HealthWorkoutActivityType.VOLLEYBALL:                return 'Volleyball';
      case HealthWorkoutActivityType.SWIMMING_OPEN_WATER:
      case HealthWorkoutActivityType.SWIMMING:                  return 'Swimming';
      case HealthWorkoutActivityType.YOGA:                      return 'Yoga';
      case HealthWorkoutActivityType.HIKING:                    return 'Hiking';
      case HealthWorkoutActivityType.STAIR_CLIMBING:            return 'Stair Climbing';
      case HealthWorkoutActivityType.JUMP_ROPE:                 return 'Jump Rope';
      case HealthWorkoutActivityType.CARDIO_DANCE:
      case HealthWorkoutActivityType.SOCIAL_DANCE:              return 'Dance';
      default:                                                   return 'Workout';
    }
  }

  String get emoji {
    switch (activityType) {
      case HealthWorkoutActivityType.WALKING:                   return '🚶';
      case HealthWorkoutActivityType.RUNNING:                   return '🏃';
      case HealthWorkoutActivityType.BIKING:
      case HealthWorkoutActivityType.HAND_CYCLING:              return '🚴';
      case HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING:
      case HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
      case HealthWorkoutActivityType.CROSS_TRAINING:            return '💪';
      case HealthWorkoutActivityType.SOCCER:
      case HealthWorkoutActivityType.AUSTRALIAN_FOOTBALL:       return '⚽';
      case HealthWorkoutActivityType.AMERICAN_FOOTBALL:         return '🏈';
      case HealthWorkoutActivityType.BASKETBALL:                return '🏀';
      case HealthWorkoutActivityType.CRICKET:                   return '🏏';
      case HealthWorkoutActivityType.BADMINTON:                 return '🏸';
      case HealthWorkoutActivityType.TENNIS:
      case HealthWorkoutActivityType.TABLE_TENNIS:              return '🎾';
      case HealthWorkoutActivityType.VOLLEYBALL:                return '🏐';
      case HealthWorkoutActivityType.SWIMMING_OPEN_WATER:
      case HealthWorkoutActivityType.SWIMMING:                  return '🏊';
      case HealthWorkoutActivityType.YOGA:                      return '🧘';
      case HealthWorkoutActivityType.HIKING:                    return '🥾';
      case HealthWorkoutActivityType.STAIR_CLIMBING:            return '🪜';
      case HealthWorkoutActivityType.JUMP_ROPE:                 return '🪂';
      case HealthWorkoutActivityType.CARDIO_DANCE:
      case HealthWorkoutActivityType.SOCIAL_DANCE:              return '💃';
      default:                                                   return '🏋️';
    }
  }

  String get durationLabel {
    final m = duration.inMinutes;
    return m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m';
  }
}

class HourlyBucket {
  final int hour;
  final int steps;
  const HourlyBucket(this.hour, this.steps);
}

class HealthService {
  static final instance = HealthService._();
  HealthService._();

  final _health = Health();

  Future<bool> requestPermissions() async {
    try {
      return await _health.requestAuthorization(_readTypes);
    } catch (_) {
      return false;
    }
  }

  Future<HealthSummary> getTodayStats() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // Fetch each type individually to isolate failures
    final steps        = await _fetch(HealthDataType.STEPS, midnight, now);
    final distance     = await _fetch(HealthDataType.DISTANCE_WALKING_RUNNING, midnight, now);
    final activeCal    = await _fetch(HealthDataType.ACTIVE_ENERGY_BURNED, midnight, now);
    final basalCal     = await _fetch(HealthDataType.BASAL_ENERGY_BURNED, midnight, now);
    final heartRateRaw = await _fetch(HealthDataType.HEART_RATE, midnight, now);
    final restingHR    = await _fetch(HealthDataType.RESTING_HEART_RATE, midnight, now);
    final exercise     = await _fetch(HealthDataType.EXERCISE_TIME, midnight, now);
    final workoutsRaw  = await _fetch(HealthDataType.WORKOUT, midnight, now);
    final flights      = await _fetch(HealthDataType.FLIGHTS_CLIMBED, midnight, now);
    final standTime    = await _fetch(HealthDataType.APPLE_STAND_TIME, midnight, now);

    // Totals
    final totalSteps      = _sumInt(steps);
    final totalMetres     = _sumDouble(distance);
    final totalActiveCal  = _sumDouble(activeCal);
    final totalBasalCal   = _sumDouble(basalCal);
    final totalActiveMins = _sumInt(exercise);
    final totalFloors     = _sumInt(flights);
    // APPLE_STAND_TIME is in seconds
    final totalStandMins  = (_sumDouble(standTime) / 60).round();

    // Heart rate
    HeartRateSummary? hrSummary;
    final hrPoints = heartRateRaw
        .map((p) => HeartRatePoint(
              p.dateFrom,
              (p.value as NumericHealthValue).numericValue.toInt(),
            ))
        .toList();
    final restingVal = restingHR.isNotEmpty
        ? (restingHR.last.value as NumericHealthValue).numericValue.toInt()
        : 0;
    if (hrPoints.isNotEmpty) {
      final bpms = hrPoints.map((p) => p.bpm).toList();
      hrSummary = HeartRateSummary(
        avg: (bpms.reduce((a, b) => a + b) / bpms.length).round(),
        min: bpms.reduce((a, b) => a < b ? a : b),
        max: bpms.reduce((a, b) => a > b ? a : b),
        resting: restingVal,
        points: hrPoints,
      );
    }

    // Workouts — totalDistance is in metres, totalEnergyBurned in kcal
    final sessions = workoutsRaw.map((p) {
      final w = p.value as WorkoutHealthValue;
      return WorkoutSession(
        start: p.dateFrom,
        end: p.dateTo,
        activityType: w.workoutActivityType,
        distanceKm: (w.totalDistance ?? 0) / 1000.0,
        calories: (w.totalEnergyBurned ?? 0).toDouble(),
      );
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    // Hourly step buckets (0–23)
    final hourlyBuckets = List.generate(24, (h) {
      final bucketStart = midnight.add(Duration(hours: h));
      final bucketEnd   = bucketStart.add(const Duration(hours: 1));
      final count = steps
          .where((p) =>
              p.dateFrom.isBefore(bucketEnd) && p.dateTo.isAfter(bucketStart))
          .fold<int>(0,
              (s, p) => s + (p.value as NumericHealthValue).numericValue.toInt());
      return HourlyBucket(h, count);
    });

    return HealthSummary(
      steps: totalSteps,
      distanceKm: totalMetres / 1000.0,
      activeCalories: totalActiveCal,
      totalCalories: totalActiveCal + totalBasalCal,
      activeMinutes: totalActiveMins,
      standMinutes: totalStandMins,
      floorsClimbed: totalFloors,
      heartRate: hrSummary,
      workouts: sessions,
      hourlySteps: hourlyBuckets,
    );
  }

  Future<List<HealthDataPoint>> _fetch(
      HealthDataType type, DateTime start, DateTime end) async {
    try {
      return await _health.getHealthDataFromTypes(
          types: [type], startTime: start, endTime: end);
    } catch (_) {
      return [];
    }
  }

  int _sumInt(List<HealthDataPoint> pts) => pts.fold(
      0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toInt());

  double _sumDouble(List<HealthDataPoint> pts) => pts.fold(
      0.0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toDouble());
}
